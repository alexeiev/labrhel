#!/bin/bash
#
# create_ex294_repo.sh
#
# Cria repositórios locais (BaseOS e AppStream) com os pacotes necessários
# para estudo da certificação RHCE EX294.
#
# Pré-requisitos:
#   - Workstation registrada com subscription-manager
#   - Repos rhel-9-for-x86_64-baseos-rpms e appstream-rpms habilitados
#   - Pacote createrepo_c instalado (dnf install createrepo_c)
#   - Apache servindo /var/www/html/
#
# Uso: sudo ./create_ex294_repo.sh
#

# ============================================================
# Configuração
# ============================================================
REPO_BASE="/var/www/html/repos/rhel9"
BASEOS_DIR="${REPO_BASE}/BaseOS"
APPSTREAM_DIR="${REPO_BASE}/AppStream"
TMP_DIR="/tmp/ex294_download"
COMPS_TMP="/tmp/ex294_comps"

# Pacotes alvo (edite aqui para adicionar/remover pacotes)
PACKAGES_LIST=(
    httpd mod_ssl
    mariadb mariadb-server
    php php-fpm php-mysqlnd
    firewalld
    rhel-system-roles
    ansible-core
    python3-blivet
    libblockdev-dm
    stratisd
    stratis-cli
)

# Grupos alvo (passados literalmente, sem array para evitar problemas
# de expansão em diferentes versões do bash)
GROUP_RPM_DEV='@RPM Development Tools'

# ============================================================
# Funções auxiliares
# ============================================================

check_prereqs() {
    echo "==> Verificando pré-requisitos..."
    for cmd in dnf createrepo_c rpm zstd gunzip xz; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "    AVISO: '$cmd' não encontrado (pode ser necessário para descompactar comps.xml)"
        fi
    done

    if ! dnf repolist --enabled 2>/dev/null | grep -q "rhel-9-for-x86_64-baseos-rpms"; then
        echo "ERRO: o repo rhel-9-for-x86_64-baseos-rpms não está habilitado."
        echo "      Registre a workstation com subscription-manager primeiro."
        exit 1
    fi
}

# Descomprime o comps.xml conforme a extensão
decompress_comps() {
    local src="$1"
    local dst="$2"

    case "$src" in
        *.zst) zstd -d -f "$src" -o "$dst" 2>/dev/null ;;
        *.gz)  gunzip -c "$src" > "$dst" ;;
        *.xz)  xz -d -c "$src" > "$dst" ;;
        *)     cp "$src" "$dst" ;;
    esac
}

# Localiza e extrai o comps.xml do cache do DNF
extract_comps() {
    local repo_pattern="$1"
    local output_file="$2"

    local comps_src
    comps_src=$(find /var/cache/dnf -path "*${repo_pattern}*" -name "*comps*.xml*" 2>/dev/null | head -1)

    if [ -z "$comps_src" ]; then
        echo "    AVISO: comps.xml não encontrado para ${repo_pattern}"
        return 1
    fi

    echo "    Encontrado: $comps_src"
    decompress_comps "$comps_src" "$output_file"
    return 0
}

# ============================================================
# Início
# ============================================================
check_prereqs

echo "==> Limpando estrutura anterior..."
rm -rf "${BASEOS_DIR}" "${APPSTREAM_DIR}" "${TMP_DIR}" "${COMPS_TMP}"
mkdir -p "${BASEOS_DIR}" "${APPSTREAM_DIR}" "${TMP_DIR}" "${COMPS_TMP}"

# ============================================================
# Atualiza cache da workstation (necessário para extrair comps.xml)
# ============================================================
echo "==> Atualizando cache do DNF da workstation..."
dnf makecache --refresh >/dev/null 2>&1

# ============================================================
# Download dos pacotes individuais
# ============================================================
echo "==> Baixando pacotes alvo + dependências (${#PACKAGES_LIST[@]} pacotes)..."
cd "${TMP_DIR}" || exit 1
dnf download --resolve --alldeps --arch=x86_64,noarch "${PACKAGES_LIST[@]}"

if [ $? -ne 0 ]; then
    echo "ERRO no dnf download. Abortando."
    exit 1
fi

# ============================================================
# Download do grupo "RPM Development Tools"
# ============================================================
echo "==> Baixando grupo 'RPM Development Tools'..."
dnf install -y --downloadonly --downloaddir="${TMP_DIR}" "${GROUP_RPM_DEV}"

if [ $? -ne 0 ]; then
    echo "    Tentando sintaxe alternativa..."
    dnf group install -y --downloadonly --downloaddir="${TMP_DIR}" "RPM Development Tools"
fi

total=$(ls -1 ${TMP_DIR}/*.rpm 2>/dev/null | wc -l)
echo "==> Total baixado: $total RPMs"

if [ "$total" -eq 0 ]; then
    echo "ERRO: nenhum RPM foi baixado. Abortando."
    exit 1
fi

# ============================================================
# Separa entre BaseOS e AppStream usando lista upstream
# ============================================================
echo "==> Listando pacotes do BaseOS upstream..."
BASEOS_LIST=$(mktemp)
dnf repoquery --repo=rhel-9-for-x86_64-baseos-rpms --qf '%{name}\n' 2>/dev/null \
    | sort -u > "${BASEOS_LIST}"
echo "    $(wc -l < ${BASEOS_LIST}) pacotes únicos no BaseOS upstream"

echo "==> Separando pacotes entre BaseOS e AppStream..."
cd "${TMP_DIR}" || exit 1

count_base=0
count_app=0

for rpm in *.rpm; do
    [ -f "$rpm" ] || continue
    pkg_name=$(rpm -qp --queryformat '%{NAME}' "$rpm" 2>/dev/null)

    if grep -qx "$pkg_name" "${BASEOS_LIST}"; then
        mv "$rpm" "${BASEOS_DIR}/"
        count_base=$((count_base + 1))
    else
        mv "$rpm" "${APPSTREAM_DIR}/"
        count_app=$((count_app + 1))
    fi
done

rm -f "${BASEOS_LIST}"

echo "    BaseOS:    $count_base RPMs"
echo "    AppStream: $count_app RPMs"

# ============================================================
# Extrai comps.xml dos metadados upstream
# ============================================================
echo "==> Extraindo comps.xml dos repos upstream..."

extract_comps "baseos" "${COMPS_TMP}/comps-baseos.xml"
COMPS_BASE_OK=$?

extract_comps "appstream" "${COMPS_TMP}/comps-appstream.xml"
COMPS_APP_OK=$?

# ============================================================
# Gera metadados (com comps.xml quando disponível)
# ============================================================
echo "==> Gerando metadados do BaseOS..."
if [ $COMPS_BASE_OK -eq 0 ] && [ -f "${COMPS_TMP}/comps-baseos.xml" ]; then
    createrepo_c -g "${COMPS_TMP}/comps-baseos.xml" "${BASEOS_DIR}"
else
    echo "    (sem comps.xml, gerando sem grupos)"
    createrepo_c "${BASEOS_DIR}"
fi

echo "==> Gerando metadados do AppStream..."
if [ $COMPS_APP_OK -eq 0 ] && [ -f "${COMPS_TMP}/comps-appstream.xml" ]; then
    createrepo_c -g "${COMPS_TMP}/comps-appstream.xml" "${APPSTREAM_DIR}"
else
    echo "    (sem comps.xml, gerando sem grupos)"
    createrepo_c "${APPSTREAM_DIR}"
fi

# ============================================================
# Permissões e SELinux
# ============================================================
echo "==> Ajustando permissões e SELinux..."
chown -R apache:apache "${REPO_BASE}" 2>/dev/null || chown -R root:root "${REPO_BASE}"
chmod -R 755 "${REPO_BASE}"

if command -v restorecon &>/dev/null; then
    restorecon -Rv "${REPO_BASE}" >/dev/null 2>&1 || true
fi

# ============================================================
# Limpeza
# ============================================================
rm -rf "${TMP_DIR}" "${COMPS_TMP}"

# ============================================================
# Resumo final
# ============================================================
size_base=$(du -sh "${BASEOS_DIR}" | cut -f1)
size_app=$(du -sh "${APPSTREAM_DIR}" | cut -f1)

echo ""
echo "============================================================"
echo "Repositórios criados com sucesso!"
echo "============================================================"
echo "  BaseOS:    ${BASEOS_DIR}"
echo "             ${size_base} (${count_base} pacotes)"
echo "  AppStream: ${APPSTREAM_DIR}"
echo "             ${size_app} (${count_app} pacotes)"
echo ""
echo "Arquivo .repo para os managed nodes:"
echo "------------------------------------------------------------"
cat <<'EOF'
[EX294_BASE]
name = EX294 BaseOS
baseurl = http://content.example.com/rhel9/BaseOS
enabled = 1
gpgcheck = 0

[EX294_STREAM]
name = EX294 AppStream
baseurl = http://content.example.com/rhel9/AppStream
enabled = 1
gpgcheck = 0
EOF
echo "------------------------------------------------------------"
echo ""
echo "Nos managed nodes, depois de configurar o .repo, rode:"
echo "  sudo dnf clean all && sudo dnf makecache"
echo "============================================================"