#!/bin/bash
rojo='\033[0;31m'
verde='\033[0;32m'
azul='\033[0;34m'
reset='\033[0m'

archivo="archivo.txt"
archivo_nuevo="archivo_nuevo.txt"

sudo timeout 1m tcpdump 2>&1 | grep telecentro-reversos.com.ar > archivo.txt


limpiar_ip() {
    ip_limpia=$(echo "$1" | cut -d'-' -f2- | tr '-' '.')
    echo "$ip_limpia"
}

procesar_archivo() {
    # Archivo de texto
    local archivo="$1"
    local regex="cpe-[0-9]+-[0-9]+-[0-9]+"

    # Crear un archivo temporal para almacenar las IPs únicas
    archivo_temporal=$(mktemp)

    # Leer el archivo línea por línea y eliminar las IPs duplicadas
    while IFS= read -r linea; do
        # Buscar todas las IPs en la línea
        ips=$(echo "$linea" | grep -oE "$regex")

        # Iterar sobre las IPs encontradas
        for ip in $ips; do
            # Llamar a la función para limpiar la IP
            ip_limpia=$(limpiar_ip "$ip")
            echo "$ip_limpia"
        done
    done < "$archivo" | sort -u > "$archivo_temporal"

    # Crear un nuevo archivo con el contenido del archivo temporal
    if [ -s "$archivo_temporal" ]; then
        cp "$archivo_temporal" "$archivo_nuevo"
        echo -e "${azul}\nSe creó un nuevo archivo con las IPs únicas: $archivo_nuevo${reset}\n"
    else
        echo -e "${rojo}No se encontraron IPs únicas en el archivo${reset}"
    fi

    rm "$archivo_temporal"
}

add_iptables(){
local archivo_nuevo="$1"
while IFS= read -r linea; do
    ips=$(echo "$linea")
    for ip in $ips; do
        
        if iptables-save | grep -q "$ip"; then
            echo -e "${rojo}La IP $ip ya está agregada en iptables${reset}"
        else
        #iptables -A OUTPUT -s 192.168.88.226 -d $ip.0/24 -j DROP
            iptables -A OUTPUT -s 192.168.88.218 -d $ip.0/24 -j DROP
            echo -e "${verde}Se agrego el siguiente rango${reset} ${azul}$ip.0/24${reset}"
            
            
        fi
    done
done < "$archivo_nuevo"
echo -e "\n ${azul}Así quedo la tabla OUTPUT de iptables${reset}"
iptables -L OUTPUT --line-numbers
echo -e "\n"
}


#llama a la función 
procesar_archivo "$archivo"

#verifica si el archivo existe y llama a la función
if [ -f "$archivo_nuevo" ]; then
    add_iptables "$archivo_nuevo"
        while true; do
            echo -e "${azul}Por favor, ingresa una opción${reset} (${rojo}S${reset}, ${verde}N${reset}) ${azul}para guardar los cambios en iptables:${reset}"
            echo -e "${rojo}Ten en cuanta que se guarda en /etc/iptables/iptables.rules${reset}"
            read opcion  
            case "$opcion" in
                "S")
                    iptables-save > /etc/iptables/iptables.rules
                    echo "Se guardo correctamente en /etc/iptables/iptables.rules"
                    break 
                    ;;
                "N")
                    echo "No se guardo ningún cambio"
                    break  
                    ;;
                *)
                    echo "Opción no válida. Por favor, ingresa una opción válida."
                    ;;
            esac
        done
else
    echo "Nada que agregar a iptable"
fi