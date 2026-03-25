$TTL 86400
@   IN  SOA     ns.zenfocus.com. admin.zenfocus.com. (
            2026032401  ; Serial
            3600        ; Refresh
            1800        ; Retry
            1200        ; Expire
            86400 )     ; Minimum TTL

; Nameservers
@       IN  NS      ns.zenfocus.com.

; A records
ns      IN  A       10.10.10.10
gitea   IN  A       10.10.10.20
www     IN  A       10.10.10.21
db      IN  A       10.10.10.22

; CNAME records
gitlab  IN  CNAME   gitea.zenfocus.com.
