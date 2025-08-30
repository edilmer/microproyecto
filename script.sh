#!/usr/bin/env bash
# script.sh - Script de verificación y diagnóstico para el microproyecto
# Uso: ./script.sh [comando]

set -euo pipefail

# Función para verificar el estado del sistema
check_system() {
    print_status "INFO" "Verificando estado del sistema..."
    
    # Verificar VMs
    echo -e "\n${BLUE}Estado de las VMs:${NC}"
    vagrant status
    
    # Verificar conectividad básica
    echo -e "\n${BLUE}Verificando conectividad:${NC}"
    if curl -s --connect-timeout 5 http://localhost:8080 > /dev/null; then
        print_status "OK" "Aplicación respondiendo en puerto 8080"
    else
        print_status "ERROR" "Aplicación no responde en puerto 8080"
    fi
    
    if curl -s --connect-timeout 5 http://localhost:8500 > /dev/null; then
        print_status "OK" "Consul UI disponible en puerto 8500"
    else
        print_status "ERROR" "Consul UI no disponible en puerto 8500"
    fi
    
    if curl -s --connect-timeout 5 http://localhost:8404 > /dev/null; then
        print_status "OK" "HAProxy stats disponible en puerto 8404"
    else
        print_status "ERROR" "HAProxy stats no disponible en puerto 8404"
    fi
}

# Función para verificar servicios internos 
check_services() {
    print_status "INFO" "Verificando servicios internos..."
    
    echo -e "\n${BLUE}Estado de Consul en balanceador:${NC}"
    vagrant ssh balanceador -c "sudo systemctl is-active consul && echo 'Consul OK' || echo 'Consul ERROR'"
    
    echo -e "\n${BLUE}Estado de HAProxy en balanceador:${NC}"
    vagrant ssh balanceador -c "sudo systemctl is-active haproxy && echo 'HAProxy OK' || echo 'HAProxy ERROR'"
    
    echo -e "\n${BLUE}Estado de servicios en web1:${NC}"
    vagrant ssh web1 -c "sudo systemctl is-active consul && echo 'Consul OK' || echo 'Consul ERROR'"
    vagrant ssh web1 -c "sudo systemctl is-active nodeapp@3000 && echo 'NodeApp 3000 OK' || echo 'NodeApp 3000 ERROR'"
    
    echo -e "\n${BLUE}Estado de servicios en web2:${NC}"
    vagrant ssh web2 -c "sudo systemctl is-active consul && echo 'Consul OK' || echo 'Consul ERROR'"
    vagrant ssh web2 -c "sudo systemctl is-active nodeapp@3000 && echo 'NodeApp 3000 OK' || echo 'NodeApp 3000 ERROR'"
} 

# Función para probar el balanceador
test_load_balancer() {
    print_status "INFO" "Probando balanceador de carga..."
    
    echo -e "\n${BLUE}Realizando 10 peticiones para verificar balanceo:${NC}"
    for i in {1..10}; do
        response=$(curl -s http://localhost:8080 2>/dev/null || echo "ERROR")
        if [[ "$response" == "ERROR" ]]; then
            print_status "ERROR" "Petición $i falló"
        else
            echo "Petición $i: $response"
        fi
        sleep 0.5
    done
}

# Función para reiniciar servicios
restart_services() {
    print_status "INFO" "Reiniciando servicios..."
    
    print_status "WARNING" "Reiniciando Consul y HAProxy en balanceador..."
    vagrant ssh balanceador -c "sudo systemctl restart consul haproxy"
    
    print_status "WARNING" "Reiniciando servicios en web1..."
    vagrant ssh web1 -c "sudo systemctl restart consul"
    
    print_status "WARNING" "Reiniciando servicios en web2..."
    vagrant ssh web2 -c "sudo systemctl restart consul"
    
    print_status "INFO" "Esperando 10 segundos para que los servicios se estabilicen..."
    sleep 10
    
    print_status "OK" "Servicios reiniciados"
}

# Función para ejecutar pruebas de carga
run_artillery() {
    print_status "INFO" "Ejecutando pruebas de carga con Artillery..."
    
    if ! command -v artillery >/dev/null 2>&1; then
        print_status "ERROR" "Artillery no está instalado"
        print_status "INFO" "Para instalar: npm install -g artillery"
        return 1
    fi
    
    artillery run artillery.yml
}

# Función para limpiar el entorno
cleanup() {
    print_status "WARNING" "Destruyendo VMs..."
    vagrant destroy -f
    print_status "OK" "Entorno limpio"
}

# Función de ayuda
show_help() {
    echo -e "${BLUE}Script de verificación para el microproyecto HAProxy + Consul + Node.js${NC}"
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  check          - Verificar estado general del sistema"
    echo "  services       - Verificar estado de servicios internos"  
    echo "  test           - Probar balanceador con peticiones"
    echo "  restart        - Reiniciar todos los servicios"
    echo "  artillery      - Ejecutar pruebas de carga"
    echo "  cleanup        - Destruir todas las VMs"
    echo "  help           - Mostrar esta ayuda"
    echo ""
    echo "Si no se especifica comando, se ejecuta 'check' por defecto"
}

# Main
main() {
    local command=${1:-"check"}
    
    case $command in
        "check")
            check_system
            ;;
        "services")
            check_services
            ;;
        "test")
            test_load_balancer
            ;;
        "restart")
            restart_services
            ;;
        "artillery")
            run_artillery
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_status "ERROR" "Comando desconocido: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"

