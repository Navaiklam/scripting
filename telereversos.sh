#!/bin/bash
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
        echo "Se creó un nuevo archivo con las IPs únicas: $archivo_nuevo"
    else
        echo "No se encontraron IPs únicas en el archivo."
    fi


    rm "$archivo_temporal"
}

add_iptables(){
local archivo_nuevo="$1"
while IFS= read -r linea; do
    ips=$(echo "$linea")
    for ip in $ips; do
        
        if iptables-save | grep -q "$ip"; then
            echo "La IP $ip ya está agregada en iptables"
        else
        #iptables -A OUTPUT -s 192.168.88.226 -d $ip.0/24 -j DROP
            iptables -A OUTPUT -s 192.168.88.218 -d $ip.0/24 -j DROP
            echo "Se agrego el siguiente rango $ip.0/24"
            
            
        fi
    done
done < "$archivo_nuevo"
echo -e "Así quedo la tabla OUTPUT de iptables \n"
iptables -L OUTPUT --line-numbers
}


#llama a la función 
procesar_archivo "$archivo"

#verifica si el archivo existe y llama a la función
if [ -f "$archivo_nuevo" ]; then
    add_iptables "$archivo_nuevo"
    while true; do
        echo "Por favor, ingresa una opción (s, n) para guardar los cambios en iptables:"
        echo "Ten en cuanta que se guarda en /etc/iptables/iptables.rules"
        read opcion  
        case "$opcion" in
            "s")
                iptables-save > /etc/iptables/iptables.rules
                echo "Se guardo correctamente en /etc/iptables/iptables.rules"
                break 
                ;;
            "n")
                echo "No se guardo ningún cambio"
                break  
                ;;
            *)
                echo "Opción no válida. Por favor, ingresa una opción válida."
                ;;
        esac
    done
else
    echo "Nada que agregar a iptable SI/NO"
fi
