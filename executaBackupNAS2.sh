#!/bin/bash

ZONA=$1
IP_NAS=$2
PORTA_NAS=873
DATA=$(date +%Y%m%d-%H%M)

DIRETORIO_BACKUP=${DIR_INSTALL}/backups/zona${ZONA}/atual
DIRETORIO_ALTERACOES=${DIR_INSTALL}/backups/zona${ZONA}/alteracoes/${DATA}
DIRETORIO_LOG_ZONA=${DIR_INSTALL}/backups/zona${ZONA}/logs
DIRETORIO_LOGS=${DIR_INSTALL}/logs
EXCLUDES=${DIR_INSTALL}/excludes

export PATH=$PATH:/bin:/usr/bin:/usr/local/bin

OPTS="--progress --stats --compress --partial --chown=rsync:rsync --force --ignore-errors --delete-excluded --exclude-from=${EXCLUDES}
      --bwlimit=${VELOCIDADE_UPLOAD}KiB --delete --backup --backup-dir=${DIRETORIO_ALTERACOES} -a -h"

mkdir -p ${DIRETORIO_BACKUP}
#rm -f ${DIRETORIO_LOGS}/logRsyncZona${ZONA}.log ${DIRETORIO_LOGS}/logRsyncZona${ZONA}.err

#
# Testa a conexão com os NAS da Lenovo
#
USER_RSYNC=rsync
export RSYNC_PASSWORD=87651234
rsync -a /var/backupNAS/testersync.txt rsync://${USER_RSYNC}@${IP_NAS}:${PORTA_NAS}/zona${ZONA} 2> /dev/null
if [ $? -eq 0 ]
then
    echo "`date "+%Y%m%d %H:%M:%S"` - Iniciado backup da Zona${ZONA}" >> ${ARQUIVO_LOG}
    rsync ${OPTS} rsync://${USER_RSYNC}@${IP_NAS}:${PORTA_NAS}/zona${ZONA} ${DIRETORIO_BACKUP}/ > ${DIRETORIO_LOGS}/${DATA}-logRsyncZona${ZONA}.log 2> ${DIRETORIO_LOGS}/${DATA}-logRsyncZona${ZONA}.err
else
    #
    # Testa a conexão com os NAS da WD
    #
    USER_RSYNC=root
    export RSYNC_PASSWORD=ODc2NTEyMzQ=
    rsync -a /var/backupNAS/testersync.txt rsync://${USER_RSYNC}@${IP_NAS}:${PORTA_NAS}/zona${ZONA}
    if [ $? -eq 0 ]
    then
            echo "`date "+%Y%m%d %H:%M:%S"` - Iniciado backup da Zona${ZONA}" >> ${ARQUIVO_LOG}
            rsync ${OPTS} rsync://${USER_RSYNC}@${IP_NAS}:${PORTA_NAS}/zona${ZONA} ${DIRETORIO_BACKUP}/ > ${DIRETORIO_LOGS}/${DATA}-logRsyncZona${ZONA}.log 2> ${DIRETORIO_LOGS}/${DATA}-logRsyncZona${ZONA}.err
    else
        echo "`date "+%Y%m%d %H:%M:%S"` - Erro ao conectar no servidor rsync da Zona${ZONA}" >> ${ARQUIVO_LOG}
        exit 1
    fi
fi

cat ${DIRETORIO_LOGS}/${DATA}-logRsyncZona${ZONA}.log | grep "total size is" > /dev/null
if [ $? -eq 0 ]
then
    ARQ_CRIADOS=$(cat ${DIRETORIO_LOGS}/${DATA}-logRsyncZona${ZONA}.log | grep "Number of created files:" | awk -F ":" '{print $2}' | awk -F "(" '{print $1}' | sed 's/ //g')
    BYTES_TRANSF=$(cat ${DIRETORIO_LOGS}/${DATA}-logRsyncZona${ZONA}.log | sed -n -r 's/Total transferred file size: (.*) bytes/\1/p')
    BYTES_SEC=$(cat ${DIRETORIO_LOGS}/${DATA}-logRsyncZona${ZONA}.log | sed -n -r 's/sent .* (.*) bytes\/sec/\1/p')
    echo "`date "+%Y%m%d %H:%M:%S"` - Termino do Backup da Zona${ZONA} - Arq criados: ${ARQ_CRIADOS} - Bytes transf: ${BYTES_TRANSF}" - "Bytes/sec: ${BYTES_SEC}" >> ${ARQUIVO_LOG}
else
    echo "`date "+%Y%m%d %H:%M:%S"` - Ocorreu um Erro durante o backup da Zona${ZONA} " >> ${ARQUIVO_LOG}

    # @TODO
    # testar o arquivo .err
    #
fi

mkdir -p ${DIRETORIO_LOG_ZONA}
mv ${DIRETORIO_LOGS}/${DATA}-logRsyncZona${ZONA}.log ${DIRETORIO_LOGS}/${DATA}-logRsyncZona${ZONA}.err ${DIRETORIO_LOG_ZONA}
chown -R rsync. ${DIRETORIO_ALTERACOES}
chown -R rsync. ${DIRETORIO_LOG_ZONA}

exit 0

