#!/bin/bash
# @file generate-certs.sh
# @brief Gera CA raiz e certificado TLS assinado para um domínio Gitea.
#
# @description
#   Cria uma CA auto-assinada (ca.key + ca.crt) e um certificado de servidor
#   (DOMAIN.key + DOMAIN.crt) com Subject Alternative Name (SAN), exigido por
#   navegadores modernos (Chrome, Firefox, Brave) a partir de 2017.
#
#   Sem SAN o navegador rejeita o certificado com:
#     - SSL_ERROR_BAD_CERT_DOMAIN  (Firefox)
#     - NET::ERR_CERT_COMMON_NAME_INVALID  (Chrome/Brave)
#
#   Ao final, reinicia automaticamente o container do proxy (nginx) para
#   carregar os novos certificados sem precisar restartar toda a stack.
#
# @usage
#   ./generate-certs.sh [opções]
#
# @option -f, --force          Remove certificados existentes antes de gerar novos.
#                              Por padrão o script é idempotente: pula etapas cujos
#                              arquivos de saída já existam.
# @option --no-restart         Não reinicia o proxy após gerar os certificados.
# @option --proxy-name <nome>  Nome do container proxy a reiniciar.
#                              Padrão: zenfocus-gitea-proxy
#
# @env CA_DIR          Diretório de saída dos certificados.
#                      Padrão: <script>/../gitea/ssl
# @env GITEA_DOMAIN    Domínio do servidor Gitea.
#                      Padrão: gitea.zenfocus.com
# @env DAYS_VALID      Validade dos certificados em dias.
#                      Padrão: 365
#
# @example
#   # Geração normal (idempotente) com restart automático do proxy
#   ./generate-certs.sh
#
#   # Forçar regeneração completa
#   ./generate-certs.sh --force
#
#   # Gerar sem reiniciar o proxy
#   ./generate-certs.sh --no-restart
#
#   # Usar domínio e container customizados
#   GITEA_DOMAIN=git.empresa.com ./generate-certs.sh --proxy-name meu-nginx

set -euo pipefail

# ─── Configuração ────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_DIR="${CA_DIR:-$SCRIPT_DIR/../gitea/ssl}"
DOMAIN="${GITEA_DOMAIN:-gitea.zenfocus.com}"
DAYS_VALID="${DAYS_VALID:-365}"
FORCE=false
RESTART_PROXY=true
PROXY_CONTAINER="zenfocus-gitea-proxy"

# ─── Argumentos ──────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force)        FORCE=true; shift ;;
    --no-restart)      RESTART_PROXY=false; shift ;;
    --proxy-name)      PROXY_CONTAINER="$2"; shift 2 ;;
    -h|--help)
      grep '^# @' "$0" | sed 's/^# @//' | sed 's/^/  /'
      exit 0
      ;;
    *) echo "Opção desconhecida: $1  (use --help)"; exit 1 ;;
  esac
done

# ─── Helpers de log ──────────────────────────────────────────────────────────

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

log_step()    { echo -e "\n${BOLD}${CYAN}▶ $*${RESET}"; }
log_ok()      { echo -e "  ${GREEN}✔${RESET}  $*"; }
log_skip()    { echo -e "  ${YELLOW}⊘${RESET}  $* ${YELLOW}(já existe — pulando)${RESET}"; }
log_warn()    { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
log_error()   { echo -e "\n  ${RED}✖${RESET}  $*" >&2; }
log_section() { echo -e "\n${BOLD}$*${RESET}"; }

# ─── Funções ─────────────────────────────────────────────────────────────────

# @function prepare_dir
# @brief Garante que CA_DIR existe e é gravável pelo usuário corrente.
prepare_dir() {
  mkdir -p "${CA_DIR}" 2>/dev/null || true
  if [[ ! -w "${CA_DIR}" ]]; then
    log_warn "${CA_DIR} não é gravável — ajustando permissões..."
    if sudo chown -R "$(id -u):$(id -g)" "${CA_DIR}" 2>/dev/null; then
      log_ok "Permissões ajustadas."
    else
      log_error "Não foi possível gravar em ${CA_DIR}. Execute com sudo ou ajuste manualmente."
      exit 1
    fi
  fi
}

# @function needs_gen
# @brief Retorna 0 (verdadeiro) se o arquivo não existe ou --force foi passado.
# @param $1  Caminho do arquivo a verificar.
needs_gen() { [[ "$FORCE" == true || ! -f "$1" ]]; }

# @function restart_proxy
# @brief Reinicia o container proxy para recarregar os certificados.
# @description
#   Verifica se o container existe e está rodando antes de reiniciar.
#   Se não estiver rodando, apenas emite um aviso (não falha o script).
restart_proxy() {
  log_step "Reiniciando proxy (${PROXY_CONTAINER})"

  if ! docker info >/dev/null 2>&1; then
    log_warn "Docker não está acessível — proxy não reiniciado."
    return
  fi

  local status
  status=$(docker inspect -f '{{.State.Status}}' "${PROXY_CONTAINER}" 2>/dev/null || echo "not_found")

  case "$status" in
    running)
      docker restart "${PROXY_CONTAINER}" >/dev/null
      log_ok "Proxy reiniciado — novos certificados carregados."
      ;;
    not_found)
      log_warn "Container '${PROXY_CONTAINER}' não encontrado — proxy não reiniciado."
      log_warn "Se a stack ainda não está no ar, os certs serão lidos na próxima subida."
      ;;
    *)
      log_warn "Container '${PROXY_CONTAINER}' está com status '${status}' — proxy não reiniciado."
      ;;
  esac
}

# ─── Banner ──────────────────────────────────────────────────────────────────

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║       Zenfocus · Gerador de Certs TLS    ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"
echo "  Domínio   : ${DOMAIN}"
echo "  Diretório : ${CA_DIR}"
echo "  Validade  : ${DAYS_VALID} dias"
echo "  Proxy     : ${PROXY_CONTAINER}"
[[ "$FORCE" == true ]]          && echo -e "  Modo      : ${YELLOW}--force (sobrescreve existentes)${RESET}"
[[ "$RESTART_PROXY" == false ]] && echo -e "  Restart   : ${YELLOW}desativado (--no-restart)${RESET}"

prepare_dir

# ─── Limpeza (--force) ───────────────────────────────────────────────────────

if [[ "$FORCE" == true ]]; then
  log_step "Removendo certificados anteriores"
  rm -f "${CA_DIR}"/*.crt "${CA_DIR}"/*.key \
        "${CA_DIR}"/*.csr "${CA_DIR}"/*.srl "${CA_DIR}"/*.ext
  log_ok "Diretório limpo."
fi

# ─── 1. CA — chave privada ───────────────────────────────────────────────────

log_step "CA — chave privada (4096 bits)"
if needs_gen "${CA_DIR}/ca.key"; then
  openssl genrsa -out "${CA_DIR}/ca.key" 4096 2>/dev/null
  log_ok "ca.key gerado."
else
  log_skip "ca.key"
fi

# ─── 2. CA — certificado auto-assinado ───────────────────────────────────────

log_step "CA — certificado auto-assinado"
if needs_gen "${CA_DIR}/ca.crt"; then
  openssl req -new -x509 -days "${DAYS_VALID}" \
    -key "${CA_DIR}/ca.key" \
    -out "${CA_DIR}/ca.crt" \
    -subj "/C=BR/ST=Parana/L=Curitiba/O=Zenfocus Solutions/OU=IT/CN=Zenfocus CA" \
    2>/dev/null
  log_ok "ca.crt gerado."
else
  log_skip "ca.crt"
fi

# ─── 3. Servidor — chave privada ─────────────────────────────────────────────

log_step "Servidor — chave privada (2048 bits)"
if needs_gen "${CA_DIR}/${DOMAIN}.key"; then
  openssl genrsa -out "${CA_DIR}/${DOMAIN}.key" 2048 2>/dev/null
  log_ok "${DOMAIN}.key gerado."
else
  log_skip "${DOMAIN}.key"
fi

# ─── 4. Servidor — CSR ───────────────────────────────────────────────────────

log_step "Servidor — CSR (Certificate Signing Request)"
if needs_gen "${CA_DIR}/${DOMAIN}.csr"; then
  openssl req -new \
    -key "${CA_DIR}/${DOMAIN}.key" \
    -out "${CA_DIR}/${DOMAIN}.csr" \
    -subj "/C=BR/ST=Parana/L=Curitiba/O=Zenfocus Solutions/OU=IT/CN=${DOMAIN}" \
    2>/dev/null
  log_ok "${DOMAIN}.csr gerado."
else
  log_skip "${DOMAIN}.csr"
fi

# ─── 5. Extensões SAN ────────────────────────────────────────────────────────
#
# Subject Alternative Name é obrigatório em navegadores modernos.
# O CN sozinho é ignorado desde o Chrome 58 / Firefox 48.

log_step "Extensões SAN (Subject Alternative Name)"
cat > "${CA_DIR}/${DOMAIN}.ext" <<EXTEOF
authorityKeyIdentifier = keyid,issuer
basicConstraints       = CA:FALSE
keyUsage               = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage       = serverAuth
subjectAltName         = DNS:${DOMAIN}, DNS:*.${DOMAIN}, DNS:localhost, IP:127.0.0.1
EXTEOF
log_ok "${DOMAIN}.ext criado."

# ─── 6. Servidor — certificado assinado pela CA ──────────────────────────────

log_step "Servidor — certificado assinado pela CA"
if needs_gen "${CA_DIR}/${DOMAIN}.crt"; then
  openssl x509 -req \
    -days "${DAYS_VALID}" \
    -in    "${CA_DIR}/${DOMAIN}.csr" \
    -CA    "${CA_DIR}/ca.crt" \
    -CAkey "${CA_DIR}/ca.key" \
    -CAcreateserial \
    -extfile "${CA_DIR}/${DOMAIN}.ext" \
    -out "${CA_DIR}/${DOMAIN}.crt" \
    2>/dev/null
  log_ok "${DOMAIN}.crt gerado e assinado."
else
  log_skip "${DOMAIN}.crt"
fi

# ─── 7. Verificação do SAN ───────────────────────────────────────────────────

log_step "Verificando SAN no certificado final"
SAN=$(openssl x509 -in "${CA_DIR}/${DOMAIN}.crt" -noout -text 2>/dev/null \
      | grep -A1 "Subject Alternative Name" | tail -1 | xargs)

if [[ -n "$SAN" ]]; then
  log_ok "SAN encontrado: ${SAN}"
else
  log_warn "SAN não detectado — verifique o certificado manualmente."
fi

# ─── 8. Restart do proxy ─────────────────────────────────────────────────────

if [[ "$RESTART_PROXY" == true ]]; then
  restart_proxy
else
  log_warn "Restart do proxy ignorado (--no-restart)."
  log_warn "Execute manualmente: docker restart ${PROXY_CONTAINER}"
fi

# ─── Resumo ──────────────────────────────────────────────────────────────────

log_section "\n  ✅  Certificados prontos em ${CA_DIR}\n"

printf "  %-32s %s\n" "Arquivo" "Tamanho"
printf "  %-32s %s\n" "──────────────────────────────" "───────"
for f in "${CA_DIR}"/ca.crt "${CA_DIR}"/ca.key \
          "${CA_DIR}/${DOMAIN}.crt" "${CA_DIR}/${DOMAIN}.key"; do
  [[ -f "$f" ]] && printf "  %-32s %s\n" "$(basename "$f")" "$(du -sh "$f" | cut -f1)"
done

echo -e "\n  ${YELLOW}Instale ca.crt no sistema para confiar nos certificados:${RESET}"
echo "    sudo cp ${CA_DIR}/ca.crt /usr/local/share/ca-certificates/zenfocus-ca.crt"
echo "    sudo update-ca-certificates"
echo ""