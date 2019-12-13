#!/bin/bash

export VELOCIDADE_UPLOAD
export DIR_INSTALL=/var/backupNAS
export DIRETORIO_LOGS=${DIR_INSTALL}/logs
export ARQUIVO_LOG=${DIRETORIO_LOGS}/logBackupNAS.log

ARQUIVO_CADASTRO_NAS=${DIR_INSTALL}/NAS.txt

rm -f ${ARQ_NAS_BACKUP_DIA}

if [ -z $1 ]
then
    VELOCIDADE_UPLOAD=0
else
    VELOCIDADE_UPLOAD=$1
fi

${DIR_INSTALL}/finalizaBackupsAtivos.sh

while read linha
do
    ZONA=$(echo ${linha} | awk -F "," '{print $1}' | cut -d a -f 2)
    IP_NAS=$(echo ${linha} | awk -F "," '{print $2}')

    ps aux | grep "executaBackupNAS2.sh ${ZONA} ${IP_NAS}" | grep -v grep > /dev/null
    if [ $? -eq 0 ]
    then
           echo "`date "+%Y%m%d %H:%M:%S"` - Já existe instancias do rsync executando backup da zona ${ZONA}, o backup não vai ser inicializado" >> ${ARQUIVO_LOG}
    else
        pid=$(ps aux | grep "executaBackupNAS2.sh ${ZONA} ${IP_NAS}" | grep -v grep | awk '{print $2}')
        if [ -n "$pid" ]
        then
            echo "`date "+%Y%m%d %H:%M:%S"` - Foi finalizado o processo (${pid}) de backup do NAS da Zona${ZONA} que estava travado" >> ${ARQUIVO_LOG}
            kill -9 $pid 2>/dev/null 1>/dev/null
        fi
        nping --tcp -p 873 ${IP_NAS} | grep -v "TTL=0" | grep RCVD 1> /dev/null 2> /dev/null
        if [ $? -eq 0 ]
        then
            ${DIR_INSTALL}/executaBackupNAS2.sh ${ZONA} ${IP_NAS} &
        else
            echo "`date "+%Y%m%d %H:%M:%S"` - Erro no backup o NAS da Zona${ZONA} está desligado / inacessível" >> ${ARQUIVO_LOG}
        fi
        sleep 3
    fi
done < ${ARQUIVO_CADASTRO_NAS}

exit 0
