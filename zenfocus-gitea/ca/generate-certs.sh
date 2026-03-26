#!/bin/bash
# @file generate-certs.sh
# @brief Generate root CA and signed TLS certificate for a Gitea domain.
#
# @description
#   Creates a self-signed CA (ca.key + ca.crt) and a server certificate
#   (DOMAIN.key + DOMAIN.crt) including Subject Alternative Name (SAN),
#   required by modern browsers (Chrome, Firefox, Brave).
#
#   Without SAN the browser will reject the certificate with:
#     - SSL_ERROR_BAD_CERT_DOMAIN  (Firefox)
#     - NET::ERR_CERT_COMMON_NAME_INVALID  (Chrome/Brave)
#
#   At the end, optionally restarts the proxy (nginx) container so the
#   new certificates are loaded without restarting the whole stack.
#
# @usage
#   ./generate-certs.sh [options]
#
# @option -f, --force          Remove existing certificates before generating new ones.
#                              By default the script is idempotent: it skips steps
#                              whose output files already exist.
# @option --no-restart         Do not restart the proxy after generating certificates.
# @option --proxy-name <name>  Name of the proxy container to restart.
#                              Default: zenfocus-gitea-proxy
#
# @env CA_DIR          Output directory for certificates.
#                      Default: <script>/../gitea/ssl
# @env GITEA_DOMAIN    Gitea server domain.
#                      Default: gitea.zenfocus.com
# @env DAYS_VALID      Certificate validity in days.
#                      Default: 365
#
# @example
#   # Normal generation (idempotent) with automatic proxy restart
#   ./generate-certs.sh
#
#   # Force full regeneration
#   ./generate-certs.sh --force
#
#   # Generate without restarting the proxy
#   ./generate-certs.sh --no-restart
#
#   # Use custom domain and proxy container name
#   GITEA_DOMAIN=git.example.com ./generate-certs.sh --proxy-name my-proxy

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_DIR="${CA_DIR:-$SCRIPT_DIR/../gitea/ssl}"
DOMAIN="${GITEA_DOMAIN:-gitea.zenfocus.com}"
DAYS_VALID="${DAYS_VALID:-365}"
FORCE=false
RESTART_PROXY=true
PROXY_CONTAINER="zenfocus-gitea-proxy"

# ─── Arguments ───────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force)        FORCE=true; shift ;;
    --no-restart)      RESTART_PROXY=false; shift ;;
    --proxy-name)      PROXY_CONTAINER="$2"; shift 2 ;;
    -h|--help)
      grep '^# @' "$0" | sed 's/^# @//' | sed 's/^/  /'
      exit 0
      ;;
    *) echo "Unknown option: $1  (use --help)"; exit 1 ;;
  esac
done

# ─── Logging helpers ─────────────────────────────────────────────────────────

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

log_step()    { echo -e "\n${BOLD}${CYAN}▶ $*${RESET}"; }
log_ok()      { echo -e "  ${GREEN}✔${RESET}  $*"; }
log_skip()    { echo -e "  ${YELLOW}⊘${RESET}  $* ${YELLOW}(already exists — skipping)${RESET}"; }
log_warn()    { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
log_error()   { echo -e "\n  ${RED}✖${RESET}  $*" >&2; }
log_section() { echo -e "\n${BOLD}$*${RESET}"; }

# ─── Functions ───────────────────────────────────────────────────────────────

# @function prepare_dir
# @brief Ensure CA_DIR exists and is writable by the current user.
prepare_dir() {
  mkdir -p "${CA_DIR}" 2>/dev/null || true
  if [[ ! -w "${CA_DIR}" ]]; then
    log_warn "${CA_DIR} is not writable — attempting to fix permissions..."
    if sudo chown -R "$(id -u):$(id -g)" "${CA_DIR}" 2>/dev/null; then
      log_ok "Permissions adjusted."
    else
      log_error "Unable to write to ${CA_DIR}. Run with sudo or adjust permissions manually."
      exit 1
    fi
  fi
}

# @function needs_gen
# @brief Return 0 (true) if the file does not exist or --force was passed.
# @param $1  Path of the file to check.
needs_gen() { [[ "$FORCE" == true || ! -f "$1" ]]; }

# @function restart_proxy
# @brief Restart the proxy container to reload certificates.
# @description
#   Checks if the container exists and is running before restarting.
#   If the container is not running it emits a warning (does not fail the script).
restart_proxy() {
  log_step "Restarting proxy (${PROXY_CONTAINER})"

  if ! docker info >/dev/null 2>&1; then
    log_warn "Docker not accessible — proxy not restarted."
    return
  fi

  local status
  status=$(docker inspect -f '{{.State.Status}}' "${PROXY_CONTAINER}" 2>/dev/null || echo "not_found")

  case "$status" in
    running)
      docker restart "${PROXY_CONTAINER}" >/dev/null
      log_ok "Proxy restarted — new certificates loaded."
      ;;
    not_found)
      log_warn "Container '${PROXY_CONTAINER}' not found — proxy not restarted."
      log_warn "If the stack is not up yet, certificates will be read on next startup."
      ;;
    *)
      log_warn "Container '${PROXY_CONTAINER}' is in status '${status}' — proxy not restarted."
      ;;
  esac
}

# ─── Banner ──────────────────────────────────────────────────────────────────

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║       Zenfocus · TLS Certificate Maker   ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"
echo "  Domain    : ${DOMAIN}"
echo "  Directory : ${CA_DIR}"
echo "  Validity  : ${DAYS_VALID} days"
echo "  Proxy     : ${PROXY_CONTAINER}"
[[ "$FORCE" == true ]]          && echo -e "  Mode      : ${YELLOW}--force (overwrite existing)${RESET}"
[[ "$RESTART_PROXY" == false ]] && echo -e "  Restart   : ${YELLOW}disabled (--no-restart)${RESET}"

prepare_dir

# ─── Cleanup (--force) ───────────────────────────────────────────────────────

if [[ "$FORCE" == true ]]; then
  log_step "Removing previous certificates"
  rm -f "${CA_DIR}"/*.crt "${CA_DIR}"/*.key \
        "${CA_DIR}"/*.csr "${CA_DIR}"/*.srl "${CA_DIR}"/*.ext
  log_ok "Directory cleaned."
fi

# ─── 1. CA — private key ───────────────────────────────────────────────────

log_step "CA — private key (4096 bits)"
if needs_gen "${CA_DIR}/ca.key"; then
  openssl genrsa -out "${CA_DIR}/ca.key" 4096 2>/dev/null
  log_ok "ca.key generated."
else
  log_skip "ca.key"
fi

# ─── 2. CA — self-signed certificate ───────────────────────────────────────

log_step "CA — self-signed certificate"
if needs_gen "${CA_DIR}/ca.crt"; then
  openssl req -new -x509 -days "${DAYS_VALID}" \
    -key "${CA_DIR}/ca.key" \
    -out "${CA_DIR}/ca.crt" \
    -subj "/C=BR/ST=Parana/L=Curitiba/O=Zenfocus Solutions/OU=IT/CN=Zenfocus CA" \
    2>/dev/null
  log_ok "ca.crt generated."
else
  log_skip "ca.crt"
fi

# ─── 3. Server — private key ─────────────────────────────────────────────

log_step "Server — private key (2048 bits)"
if needs_gen "${CA_DIR}/${DOMAIN}.key"; then
  openssl genrsa -out "${CA_DIR}/${DOMAIN}.key" 2048 2>/dev/null
  log_ok "${DOMAIN}.key generated."
else
  log_skip "${DOMAIN}.key"
fi

# ─── 4. Server — CSR ───────────────────────────────────────────────────────

log_step "Server — CSR (Certificate Signing Request)"
if needs_gen "${CA_DIR}/${DOMAIN}.csr"; then
  openssl req -new \
    -key "${CA_DIR}/${DOMAIN}.key" \
    -out "${CA_DIR}/${DOMAIN}.csr" \
    -subj "/C=BR/ST=Parana/L=Curitiba/O=Zenfocus Solutions/OU=IT/CN=${DOMAIN}" \
    2>/dev/null
  log_ok "${DOMAIN}.csr generated."
else
  log_skip "${DOMAIN}.csr"
fi

# ─── 5. SAN extensions ───────────────────────────────────────────────────────
#
# Subject Alternative Name is required by modern browsers.
# The CN field alone has been ignored since Chrome 58 / Firefox 48.

log_step "SAN extensions (Subject Alternative Name)"
cat > "${CA_DIR}/${DOMAIN}.ext" <<EXTEOF
authorityKeyIdentifier = keyid,issuer
basicConstraints       = CA:FALSE
keyUsage               = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage       = serverAuth
subjectAltName         = DNS:${DOMAIN}, DNS:*.${DOMAIN}, DNS:localhost, IP:127.0.0.1
EXTEOF
log_ok "${DOMAIN}.ext created."

# ─── 6. Server — certificate signed by CA ──────────────────────────────────

log_step "Server — certificate signed by CA"
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
  log_ok "${DOMAIN}.crt generated and signed."
else
  log_skip "${DOMAIN}.crt"
fi

# ─── 7. SAN verification ───────────────────────────────────────────────────

log_step "Checking SAN in final certificate"
SAN=$(openssl x509 -in "${CA_DIR}/${DOMAIN}.crt" -noout -text 2>/dev/null \
      | grep -A1 "Subject Alternative Name" | tail -1 | xargs)

if [[ -n "$SAN" ]]; then
  log_ok "SAN found: ${SAN}"
else
  log_warn "SAN not detected — check the certificate manually."
fi

# ─── 8. Proxy restart ─────────────────────────────────────────────────────

if [[ "$RESTART_PROXY" == true ]]; then
  restart_proxy
else
  log_warn "Proxy restart skipped (--no-restart)."
  log_warn "Run manually: docker restart ${PROXY_CONTAINER}"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────

log_section "\n  ✅  Certificates ready in ${CA_DIR}\n"

printf "  %-32s %s\n" "File" "Size"
printf "  %-32s %s\n" "──────────────────────────────" "───────"
for f in "${CA_DIR}"/ca.crt "${CA_DIR}"/ca.key \
          "${CA_DIR}/${DOMAIN}.crt" "${CA_DIR}/${DOMAIN}.key"; do
  [[ -f "$f" ]] && printf "  %-32s %s\n" "$(basename "$f")" "$(du -sh "$f" | cut -f1)"
done

echo -e "\n  ${YELLOW}Install ca.crt on the system to trust the certificates:${RESET}"
echo "    sudo cp ${CA_DIR}/ca.crt /usr/local/share/ca-certificates/zenfocus-ca.crt"
echo "    sudo update-ca-certificates"
echo ""