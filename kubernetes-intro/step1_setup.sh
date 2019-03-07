#!/bin/sh -eux

KATACODA_HOSTS_ENV_PATH=/opt/hosts.env
until [ -f "$KATACODA_HOSTS_ENV_PATH" ]; do sleep 1; done;
. "$KATACODA_HOSTS_ENV_PATH"

DOCKER_UPGRADE_DONE_MARKER_PATH=/opt/upgrade-docker-done
REGISTRY_DOMAIN=registry.local;
REGISTRY_IP=$HOST2_IP;
MASTER_IP=$HOST1_IP;
CERTS_PATH=~/.certs.src;

alias simple_date="date +'%H:%M:%S'"

sloppySSH() {
    /usr/bin/ssh -oBatchMode=yes -o TCPKeepAlive=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=30 -o ConnectTimeout=30 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=error "$@";
}

sloppySCP() {
    /usr/bin/scp -oBatchMode=yes -o TCPKeepAlive=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=30 -o ConnectTimeout=30 -o ConnectionAttempts=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=error "$@";
}

waitForDockerRegistryLocal() {
    until 2>&1 docker inspect -f '{{.ID}}' registry; do
        echo .; sleep 0.5;
    done
}

waitForDockerDaemon() {
    until 2>&1 docker version; do
        echo ., sleep 0.5;
    done;
}

waitForDockerUpgrade() {
    until [ -e "$DOCKER_UPGRADE_DONE_MARKER_PATH" ]; do
        echo ., sleep 0.5;
    done;
}

waitForDockerRegistryRemote() {
    until 2>&1 curl --fail -L https://"$REGISTRY_DOMAIN"/v2/; do
        echo .; sleep 0.5;
    done;
}

waitForKubernetes() {
    until 2>&1 kubectl -v1 --request-timeout=1s version; do
        echo .; sleep 0.5;
    done
}

waitForWeave() {
    until
        numberReady=$(2>&1 kubectl get daemonset -n kube-system weave-net -o jsonpath='{.status.numberReady}') &&
        numberDesired=$(2>&1 kubectl get daemonset -n kube-system weave-net -o jsonpath='{.status.desiredNumberScheduled}') &&
        [ "$numberReady" = "$numberDesired" ];
    do
        echo .; sleep 0.5;
    done;
}

deployIngressController() {
    curl -sSL https://gist.github.com/mlindhout/6ca5ff047ee7891350e81ce763015402/raw/ |
        sed "s/HOST_IP/$MASTER_IP/" |
        2>&1 kubectl -v1 apply -f -;
}

deployPVController() {
    curl -sSL https://gist.github.com/mlindhout/ca560484366888263c96e00ad2b445d9/raw |
    2>&1 kubectl -v1 apply -f -;
}

deployDashboard() {
    2>&1 kubectl -v1 apply -f https://gist.github.com/mlindhout/93ded3fad785e76b969ed3d323e3f380/raw//;
}

waitForDashboard() {
    2>&1 kubectl -v1 wait --timeout=1m -n kube-system deployment/kubernetes-dashboard --for condition=Available;
}

installTools() {
    (
        exec 2>&1
        installKustomize &
        installDockerCompose &
        installStern &
        wait
    )
}

installKustomize() {
    until 2>&1 curl --fail -kLo /usr/local/bin/kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v2.0.1/kustomize_2.0.1_linux_amd64; do
        echo .; sleep 0.5;
    done;
    chmod +x /usr/local/bin/kustomize;
}

installDockerCompose() {
    until 2>&1 curl --fail -kLo /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/1.24.0-rc1/docker-compose-"$(uname -s)"-"$(uname -m)"; do
        echo .; sleep 0.5;
    done;
    chmod +x /usr/local/bin/docker-compose;
}

installStern() {
    until 2>&1 curl --fail -Lo /usr/local/bin/stern https://github.com/wercker/stern/releases/download/1.10.0/stern_linux_amd64; do
        echo .; sleep 0.5;
    done;
    chmod +x /usr/local/bin/stern;
}

installStdinSpinner() {
    until 2>/dev/null curl --fail -ksSL https://github.com/sgreben/stdin-spinner/releases/download/1.0.4/stdin-spinner_1.0.4_linux_x86_64.tar.gz | tar xz; do
        sleep 0.5;
    done;
    chmod +x stdin-spinner
    mv stdin-spinner /usr/bin/
}

configureGit() {
    (
        ssh-keyscan github.com >> ~/.ssh/known_hosts
        git config --global user.email "mail@example.com"
        git config --global user.name "name"
    ) 2>&1
}

configureSSH() {
    (
        rm -f ~/.ssh/id_rsa;
        ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
        chmod 400 ~/.ssh/id_rsa;
        cat >> ~/.bashrc <<EOF
        >/dev/null 2>/dev/null eval "\$(ssh-agent)";
        >/dev/null 2>/dev/null ssh-add ~/.ssh/id_rsa;
        alias g=git;
        alias k=kubectl;
        . /opt/setup_helpers.sh.inc;
EOF
    ) 2>/dev/null >/dev/null;
    cat <<EOF
$(simple_date)] SSH public key:

$(cat ~/.ssh/id_rsa.pub)

EOF
}

runDockerRegistry() {
    2>&1 docker run --restart=always -d -p 443:5000 \
        -v /root/.certs:/certs \
        -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/$REGISTRY_DOMAIN.crt \
        -e REGISTRY_HTTP_TLS_KEY=/certs/$REGISTRY_DOMAIN.key \
        -v /opt/registry/data:/var/lib/registry \
        --name registry registry:2;
}

hideCursor() {
    printf "\033[?25l";
}

restoreCursor() {
    printf "\033[?25h";
}

main_master() {
    clear;
    echo "[$(simple_date)] Setting up... (~2 min)"
        installTools &
        prePullImages &
        (
            configureGit;
            upgradeCluster;
            waitForKubernetes;
            deployDashboard;
            deployIngressController;
            deployPVController;
        )
    echo "[$(simple_date)] done"
    configureSSH;
    bash;
}

main_node01() {
    clear;
    echo "[$(simple_date)] Setting up... (~1 min)"
    prePullImages &
    installStern &
    wait;
    waitForDockerUpgrade;
    runDockerRegistry;
    waitForDockerRegistryLocal;
    waitForKubernetes;
    echo "[$(simple_date)] done"
    echo '# log output from your apps in the default namespace will appear below.'
    echo 'node01 $ stern ""'
    stern ""
}

main() {
    case "$(hostname)" in
        master)
            main_master
        ;;
        node01)
            main_node01
        ;;
    esac
}

upgradeCluster() {
    exec 2>&1;
    kubectl wait --for condition=Ready node/master;
    setUpRegistryEtcHostsOn node01;
    setUpRegistryEtcHostsOn localhost;
    setUpMasterEtcHostsOn node01;
    copyKubeconfigTo node01;
    waitForWeave;
    generateCertsIn "$CERTS_PATH";
    stopKubeletOn node01;
    stopKubeletOn master;
    (
        aptGetUpdateOn node01;
        stopDockerOn node01;
        setUpCertsOn "$CERTS_PATH" node01;
        upgradeDockerOn node01;
        startDockerOn node01;
    ) &
    (
        aptGetUpdateOn localhost;
        stopDockerOn localhost;
        setUpCertsOn "$CERTS_PATH" localhost;
        upgradeDockerOn localhost;
        startDockerOn localhost;
        waitForDockerDaemon;
    ) &
    wait;
    startKubeletOn master;
    startKubeletOn node01;
    waitForKubernetes;
    waitForWeave;
}


aptGetUpdateOn() {
    HOST="$1";
    2>&1 sloppySSH root@"$HOST" "
        export DEBIAN_FRONTEND=noninteractive;
        apt-get -y update;
    ";
}

stopKubeletOn() {
    HOST="$1"
    2>&1 sloppySSH root@"$HOST" "
        service kubelet stop;
    ";
}

startKubeletOn() {
    HOST="$1"
    2>&1 sloppySSH root@"$HOST" "
        service kubelet start;
    ";
}

stopDockerOn() {
    HOST="$1"
    2>&1 sloppySSH root@"$HOST" "
        service docker stop;
    ";
}

startDockerOn() {
    HOST="$1"
    2>&1 sloppySSH root@"$HOST" "
        systemctl daemon-reload;
        service docker start;
    ";
}

upgradeDockerOn() {
    HOST="$1";

    2>&1 sloppySSH root@"$HOST" "
        mkdir -p /etc/systemd/system/docker.service.d;
        cat > /etc/systemd/system/docker.service.d/docker.conf;
    " <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF
    2>&1 sloppySSH root@"$HOST" "
        export DEBIAN_FRONTEND=noninteractive;
        apt-get install --no-install-recommends -y docker.io;
        touch $DOCKER_UPGRADE_DONE_MARKER_PATH;
    ";
}

copyKubeconfigTo() {
    HOST="$1";
    until [ -f /root/.kube/config ]; do
        sleep 1;
    done;
    2>&1 sloppySSH root@"$HOST" "
        mkdir -p /root/.kube/;
    ";
    sloppySCP /root/.kube/config root@"$HOST":/root/.kube/
}

setUpRegistryEtcHostsOn() {
    HOST="$1";
    2>&1 sloppySSH root@"$HOST" "
        echo '${REGISTRY_IP}' '${REGISTRY_DOMAIN}' >> /etc/hosts
    "
}

setUpMasterEtcHostsOn() {
    HOST="$1";
    2>&1 sloppySSH root@"$HOST" "
        echo '${MASTER_IP}' master >> /etc/hosts
    "
}

generateCertsIn() {
    export REGISTRY_DOMAIN;
    CERTS_PATH="$1";
    mkdir -p "$CERTS_PATH";
    (
        set -eu;
        cd "$CERTS_PATH";
        # Generate a root key
        openssl genrsa -out rootCA.key 512;
        # Generate a root certificate
        openssl req -x509 -new -nodes -key rootCA.key -days 365 \
            -subj "/C=UK/ST=TEST/L=TEST/O=TEST/CN=${REGISTRY_DOMAIN}" \
            -out rootCA.crt;
        # Generate key for host
        openssl genrsa -out ${REGISTRY_DOMAIN}.key;
        # Generate CSR
        openssl req -new -key ${REGISTRY_DOMAIN}.key \
            -subj "/C=UK/ST=TEST/L=TEST/O=TEST/CN=${REGISTRY_DOMAIN}" \
            -out ${REGISTRY_DOMAIN}.csr;
        # Sign certificate request
        openssl x509 -req -in ${REGISTRY_DOMAIN}.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -days 365 -out ${REGISTRY_DOMAIN}.crt;
    )
}

setUpCertsOn() {
    export REGISTRY_DOMAIN;
    CERTS_PATH="$1";
    HOST="$2";
    2>&1 sloppySSH root@"$HOST" "
        mkdir -p /root/.certs;
        mkdir -p /usr/local/share/ca-certificates/${REGISTRY_DOMAIN};
        mkdir -p /etc/docker/certs.d/${REGISTRY_DOMAIN};
    ";
    sloppySCP "$CERTS_PATH"/rootCA.crt root@"$HOST":/usr/local/share/ca-certificates/${REGISTRY_DOMAIN};
    sloppySCP "$CERTS_PATH"/rootCA.crt root@"$HOST":/etc/docker/certs.d/${REGISTRY_DOMAIN}/ca.crt;
    sloppySCP -r "$CERTS_PATH"/* root@"$HOST":/root/.certs/;
    2>&1 sloppySSH root@"$HOST" "
        update-ca-certificates;
    ";
}

prePullImages() {
    2>&1 docker pull k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1 &
    2>&1 docker pull nginx/nginx-ingress:edge &
    2>&1 docker pull node:11.9.0-alpine &
    wait;
}

main;
