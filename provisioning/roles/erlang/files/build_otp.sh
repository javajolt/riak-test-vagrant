#!/bin/bash
OPENSSL=/usr/local/opt/openssl
KERL=/usr/local/kerl/kerl
INSTALLDIR=${HOME}/erlang
ERLN8=/usr/local/erln8/bin/erln8
export KERL_CONFIGURE_OPTIONS="--enable-smp-support --without-odbc --disable-hipe --enable-m64-build"
if [ -d ${OPENSSL} ]; then
    export KERL_CONFIGURE_OPTIONS="${KERL_CONFIGURE_OPTIONS} -with-ssl=${OPENSSL}"
fi
export CFLAGS="-g -O2"
export LDFLAGS="-g"
export MAKE="make -j8"
if [ -f /etc/centos-release ]; then
    export CFLAGS="-g -O2 -DOPENSSL_NO_EC=1"
fi
for release in R15B01-basho R16B02-basho10 18.3.3; do
    if [ -z "`${KERL} list builds | grep ${release}`" ]; then
         if [ "${release}" == "R15B01-basho" ]; then
             GIT_LABEL="basho_OTP_R15B01p"
         elif [ "${release}" == "18.3.3" ]; then
             GIT_LABEL="OTP-18.3.3"
         else
             GIT_LABEL="OTP_R16B02_basho10"
         fi
         ${KERL} build git git://github.com/basho/otp.git ${GIT_LABEL} ${release}
#        KERL_CONFIGURE_OPTIONS="--enable-vm-probes --with-dynamic-trace=dtrace --enable-smp-support --without-odbc --with-ssl=/usr/local/opt/openssl --with-javac=/usr/lib/jvm/java-7-oracle/bin --enable-hipe" ${KERL}/${KERL} build ${release} ${release}
    fi
    if [ -z "`${KERL} list installations | grep ${release}`" ]; then
        ${KERL} install ${release} ${INSTALLDIR}/${release}
    fi
done

## Add riak_test goodies to the test environment
BASHRC=${HOME}/.bashrc
DEFAULT=R16B02-basho10
if [ -z "`grep CURRENT_OTP ${BASHRC}`" ]; then
    cat <<EOF >> ${BASHRC}
# Location of Erlang OTP installations
export R15B01=${INSTALLDIR}/R15B01-basho
export R16B02=${INSTALLDIR}/${DEFAULT}
export CURRENT_OTP=${INSTALLDIR}/${DEFAULT}
EOF
fi
if [ -f "${ERLN8}" ]; then
    ${ERLN8} --id=R15B01-basho --link ${INSTALLDIR}/R15B01-basho
    ${ERLN8} --id=${DEFAULT} --link ${INSTALLDIR}/${DEFAULT}
    sed -i.bak "s/^system_default=$/system_default=${DEFAULT}/g" ${HOME}/.erln8.d/config
fi
