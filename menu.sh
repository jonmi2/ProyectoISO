#!/usr/bin/bash


#IMPORTANTE:
#chmod u+x menu.sh
#en /home/lsi: carpeta formulariocitas, index.html, menu.sh
#borrar /var/www/FORMULARIOCITAS (solo formulariocitas)

function empaquetaycomprimeFicherosProyecto()
{
  #empaqueta y comprime los ficheros <app.py>, <script.sql> y <requirements.txt> como el contenido de las carpeta <templates> de  la carpeta origen a un fichero con nombre “/home/$USER/formulariocitas.tar.gz”.
  cd /home/$USER/formulariocitas
  tar cvzf  /home/$USER/formulariocitas.tar.gz app.py script.sql requirements.txt templates/*
}

function eliminarMySQL()
{
#Para el servicio
sudo service mysql stop
#Elimina los paquetes +ficheros de configuración + datos
sudo apt-get purge mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-*
#servidor MySQL se desinstale completamente sin dejar archivos de residuos.
sudo apt-get autoremove
#Limpia la cache
sudo apt-get autoclean
#Para cerciorarnos de que queda todo limpio:
#Eliminar los directorios de datos de MySQL:
sudo rm -rf /var/lib/mysql
#Eliminar los archivos de configuración de MySQL:
sudo rm -rf /etc/mysql/
#Eliminar los logs
sudo rm -rf /var/log/mysql
}

function instalarMySQL()
{	#instalar servidor mysql y arrancar el servicio
	aux=$(aptitude show mysql-server | grep "State: installed")
	aux2=$(aptitude show mysql-server | grep "Estado: instalado")
	aux3=$aux$aux2
	if [ -z "$aux3" ]
	then
		echo "instalando..."
		sudo apt install mysql-server
		sudo systemctl start mysql.service
	else
		echo -e "\n"
		echo -e "ya está instalado mysql \n"
	
fi	
}

function copiarFicherosProyectoNuevaUbicacion() 
{

if test -e "/home/$USER/formulariocitas.tar.gz" ; then
	cd /var/www/formulariocitas
	tar xvzf /home/$USER/formulariocitas.tar.gz
else
	echo "No existe"
fi
}

function crearNuevaUbicacion()
{
    #para no tener problemas de permisos vamos a darle la propiedad a mi usuario:grupo.
    if [ -d /var/www/formulariocitas ]
    then
        echo -e "Ya existe el direcctorio...\n"
    else
        echo "Creando directorio..."
        sudo mkdir -p /var/www/formulariocitas
        echo "Cambiando permisos del directorio..."
        sudo chown -R $USER:$USER /var/www/formulariocitas
        echo ""
        read -p "PULSA ENTER PARA CONTINUAR..."
    fi
}
	
function crear_usuario_basesdedatos()
{
	echo -e "CREATE USER 'lsi'@'localhost' IDENTIFIED BY 'lsi';\nGRANT CREATE, ALTER, DROP, INSERT, UPDATE, INDEX, DELETE, SELECT, REFERENCES, RELOAD on *.* TO 'lsi'@'localhost' WITH GRANT OPTION;\nFLUSH PRIVILEGES;" > $HOME/crearusuariobd.sql
	#se ejecuta el script que hemos creado
	sudo mysql < $HOME/crearusuariobd.sql
}

function crearbasededatos()
{
	# crear la  base de datos “invitados” y una tabla “clientes” que contendrá las citas.
	mysql -u lsi -p < /var/www/formulariocitas/script.sql
}

function ejecutarEntornoVirtual()
{
	sudo apt update #actualiza la lista de paquetes disponibles para instalar
	sudo apt upgrade #actualiza todos los paquetes instalados a sus últimas versiones disponibles.
	sudo apt install -y python3-pip #instala el paquete python3-pip, que es el administrador de paquetes de Python 3
	sudo apt install -y python3-dev #instala el paquete python3-dev, que contiene archivos de cabecera y bibliotecas necesarias para compilar extensiones de Python.
	sudo apt install -y build-essential #nstala el paquete build-essential, que incluye herramientas y bibliotecas necesarias para compilar programas.
	sudo apt install -y libssl-dev #instala el paquete libssl-dev, que contiene archivos de desarrollo de la biblioteca OpenSSL, que son necesarios para compilar programas que utilizan OpenSSL.
	sudo apt install -y libffi-dev #Enstala el paquete libffi-dev, que contiene archivos de desarrollo de la biblioteca libffi, que son necesarios para compilar programas que utilizan libffi.
	sudo apt install -y python3-setuptools #Este comando instala el paquete python3-setuptools, que proporciona herramientas para trabajar con paquetes Python.
	
	
	#instalaremos el paquete python3-venv ya que se utilizará para crear los entornos virtuales de python. 
	sudo apt install -y python3-venv
	
	#Una vez instalados los paquetes, se creará el entorno virtual con el nombre “venv” dentro de la carpeta “/var/www/formulariocitas”. Y finalmente activaremos dicho entorno virtual llamando al script activate. 
	cd /var/www/formulariocitas
	python3 -m venv venv
	source venv/bin/activate
}

function instalarLibreriasEntornoVirtual()
{
	#activar el entorno virtual de python antes de actualizar a la versión más actual de pip. 
	cd /var/www/formulariocitas
	source venv/bin/activate
	pip install --upgrade pip
	
	#Posteriormente instalará las librerías necesarias que están contenidas en el fichero <requirements.txt>.  
	pip install -r requirements.txt
}

function probandotodoconservidordedesarrollodeflask()
{
	# ejecutar el servicio app.py  en el entorno virtual. Visualizando su servicio al insertar en el navegador la dirección que indicamos utilizando el servidor desarrollo que viene por defecto con flask.
	python3 /var/www/formulariocitas/app.py &
	firefox http://127.0.0.1:5000/
}

function instalarNGINX()
{
	aux=$(aptitude show nginx | grep "State: installed")
	aux2=$(aptitude show nginx | grep "Estado: instalado")
	aux3=$aux$aux2
	if [ -z "$aux3" ]
	then
		echo "instalando..."
		sudo apt install nginx
	else
		echo -e "\n"
		echo -e "ya está instalado NGINX \n"
	
fi	
}

function ArrancarNGINX()
{
	#arranca el servicio web si no está en marcha.
	aux=$(sudo systemctl status apache2 | grep "Active: active")
	aux2=$(sudo systemctl status apache2 | grep "Activo: activo")
	aux3=$aux$aux2
	if [ -z "$aux3" ]
	then
		echo -e "Apache esta desactivado \n"
	else
		sudo systemctl stop apache2
	
fi	
	
	aux4=$(sudo systemctl status nginx | grep "Active: active")
	aux5=$(sudo systemctl status nginx | grep "Activo: activo")
	aux6=$aux4$aux5
	if [ -z "$aux6" ]
	then
		echo "iniciando..."
		sudo systemctl start nginx
	else
		echo -e "\n"
		echo -e "ya está activo NGINX \n"
	
fi
}

function TestearPuertosNGINX()
{
	#mostrar información de por qué puerto está escuchando nginx. 
	aux=$(aptitude show net-tools | grep "State: installed")
	aux2=$(aptitude show net-tools | grep "Estado: instalado")
	aux3=$aux$aux2
	if [ -z "$aux3" ]
	then
		echo "instalando..."
		sudo apt install net-tools
fi

	sudo netstat -anp | grep nginx | head -n 2
}

function visualizarIndex()
{
	#pide abrir el navegador chrome en la página por defecto de nuestro localhost o 127.0.0.1.
	aux=$(aptitude show google-chrome-stable | grep "State: installed")
	aux2=$(aptitude show google-chrome-stable | grep "Estado: instalado")
	aux3=$aux$aux2
	if [ -z "$aux3" ]
	then
		echo "instalando..."
		wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
		sudo dpkg -i google-chrome-stable_current_amd64.deb
		sudo apt install -f
		rm google-chrome-stable_current_amd64.deb

fi

	google-chrome 127.0.0.1
}

function personalizarIndex()
{
	#sustituye la página index.nginx-debian.html que viene por defecto por una página personal del grupo llamado index.html.
	sudo rm /var/www/html/index*
	sudo cp /home/$USER/index.html /var/www/html
}

function instalarGunicorn() 
{
	#nstalar el servidor de aplicaciones Gunicorn en el entorno virtual
	cd /var/www/formulariocitas
	source venv/bin/activate

	if ! pip show gunicorn > /dev/null; then
	    echo -e "\n Instalando Gunicorn...\n"
	    pip install gunicorn
	else
	    echo -e "\n Ya está instalado Gunicorn.\n"
fi
}

function configurarGunicorn() 
{
	#el siguiente fichero se encargará de servir como punto de entrada para nuestra aplicación.
	echo -e "from app import app\nif __name__ == "__main__":\n\tapp.run()" > /var/www/formulariocitas/wsgi.py
	cd /var/www/formulariocitas
	
	#abrir la siguiente direccion en segundo plano
	google-chrome http://127.0.0.1:5000 &
	
	#Verifique si Gunicorn puede servir la aplicación correctamente usando el siguiente comando:
	gunicorn --bind 127.0.0.1:5000 wsgi:app
	
	#Y finalmente visite la dirección http://127.0.0.1:5000/ para comprobar que el cliente es atendido correctamente por gunicorn.
	#si da errores borrar con sudo lsof -i :5000 y kill -9 los procesos en el puerto 5000

}

function pasarPropiedadyPermisos()
{
	#establecer la propiedad al usuario y grupo  www-data a todos los archivos y carpetas que se encuentran bajo la carpeta </var/www> que será el usuario y grupo con lo que nginx y gunicorn lo ejecutarán.
	sudo chown -R www-data:www-data /var/www/formulariocitas
	
	#establecer los permisos 775 a todos los ficheros que pertenecen al proyecto. 
	sudo chmod -R 755 /var/www/formulariocitas
}

function crearServicioSystemdFormularioCitas()
{
	sudo bash -c 'echo -e "[Unit]\nDescription=Gunicorn instance to serve formulariocitas\nAfter=network.target\n[Service]\nUser=www-data\nGroup=www-data\nWorkingDirectory=/var/www/formulariocitas\nEnvironment="PATH=/var/www/formulariocitas/venv/bin"\nExecStart=/var/www/formulariocitas/venv/bin/gunicorn --bind 127.0.0.1:5000 wsgi:app\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/formulariocitas.service'
	
	sudo systemctl daemon-reload #cargar el demonio systemd 
	sudo systemctl start formulariocitas #arrancar el servicio formulariocitas
	sudo systemctl enable formulariocitas #habilitar el demonio para que se inicie automáticamente al iniciar el sistema 
	aux=$(systemctl status formulariocitas | grep "Active: active")
	aux2=$(systemctl status formulariocitas | grep "Activo: activo")
	aux3=$aux$aux2
	if [ -z "$aux3" ]
	then
		echo -e "El demonio formulariocitas esta desactivado \n"
	else
		echo -e "El demonio formulariocitas esta activado \n"
fi
}

function configurarNginxProxyInverso()
{
	#configurar Nginx como proxy inverso para la aplicación Flask para que escuche por el puerto 8080 en vez del puerto por defecto 80.
	sudo bash -c 'echo -e "server {
	    listen 8080;
	    server_name localhost;
	    location / {
		include proxy_params;
		proxy_pass  http://127.0.0.1:5000;
	    }
	}
	" > /etc/nginx/conf.d/formulariocitas.conf'

	#También se comprobará que no haya errores de sintaxis en ninguno de sus archivos de Nginx.
	sudo nginx -t
}

function cargarFicherosConfiguracionNginx()
{
	#obligar a NGINX a cargar los nuevos cambios de la configuración.
	sudo systemctl reload nginx
}

function rearrancarNginx()
{
	#rearrancar el demonio NGINX.
	sudo systemctl restart nginx
}

function testearVirtualHost()
{
	#testear el virtual host creado abriendo en el navegador la dirección siguiente
	google-chrome http://127.0.0.1:8080
}

function verNginxLogs()
{
	#ver los logs o errores producidos por nginx.
	cat /var/log/nginx/error.log | head -n 10
	#si solo se visualiza 1 linea es porque no hay mas
}

function copiarServidorRemoto()
{
	aux=$(aptitude show openssh-server | grep "State: installed")
	aux2=$(aptitude show openssh-server | grep "Estado: instalado")
	aux3=$aux$aux2
	if [ -z "$aux3" ]
	then
		echo "instalando..."
		sudo apt install openssh-server
	else
		echo -e "\n"
		echo -e "ya está instalado \n"
	
fi
	
	aux4=$(systemctl status ssh | grep "Active: active")
	aux5=$(systemctl status ssh | grep "Activo: activo")
	aux6=$aux4$aux5
	if [ -z "$aux6" ]
	then
		echo -e "El demonio ssh esta desactivado, activando... \n"
		sudo systemctl start ssh
	else
		echo -e "El demonio ssh esta activado \n"
fi

	#Pedir la ip del de al lado (ifconfig) donde se copiara el tar.gz y el menu.sh
	ip=""
	read -p "Introduce la ip del servidor:" ip
	
	scp /home/lsi/menu.sh lsi@$ip:/home/lsi
	scp /home/lsi/formulariocitas.tar.gz lsi@$ip:/home/lsi
	
	
	#prueba introduciendo en tu navegador local la dirección http://$ip:8080 siendo $ip la dirección remota.

}

function controlarIntentosConexionSSH()
{
	echo -e "\nLos intentos de conexión por ssh, hoy, esta semana y este mes han sido:"
	
	#en caso de querer los intentos de hoy solamente
	# Capturamos la fecha actual en un formato similar al de los registros del archivo de autenticación:     fecha_actual=$(date +"%b %e")
	
	#Filtramos el archivo de autenticación para obtener solamente los intentos de conexión de hoy (SIGUIENTES 2 LINEAS):
	#cat /var/log/auth.log | grep sshd | grep -E "Failed password|Accepted password" | grep "$fecha_actual" > auth.log.txt
	#zcat /var/log/auth.log* 2> /dev/null | grep sshd | grep -E "Failed password|Accepted password" | grep "$fecha_actual" >> auth.log.txt 


	
	cat /var/log/auth.log | grep sshd | grep -E "Failed password|Accepted password"  > auth.log.txt
	zcat /var/log/auth.log* 2> /dev/null | grep sshd | grep -E "Failed password|Accepted password"  >> auth.log.txt 
	#Enviamos los errores a /dev/null para que no se impriman cuando intenta escanear auth.log si no está con extension .gz
	less auth.log.txt | tr -s ' ' '@' > auth.log.lineaporlinea.txt
	buscar="Failed@password"
	buscar2="Accepted@password"
	#esteMes=date | tr ' ' '@' | cut -d@ -f3
	#estaSemana=
	#hoy=date | tr ' ' '@' | cut -d@ -f2
	for linea in `less auth.log.lineaporlinea.txt | grep -E "$buscar2|$buscar"` 
	do
	   user=`echo $linea | cut -d@ -f11`
	   comando=`echo $linea | cut -d@ -f6`
	   dia=`echo $linea | cut -d@ -f2`
	   mes=`echo $linea | cut -d@ -f1`
	   hora=`echo $linea | cut -d@ -f3`
	   if [ "$comando" = "Failed" ] 
	   then
	   	echo -e "\"Status: [fail] Account name: $user Date: $mes, $dia, $hora\""
	   else
	   	echo -e "\"Status: [accept] Account name: $user Date: $mes, $dia, $hora\""
	   fi
	done
	echo -e "\n"
	rm auth.log.txt  auth.log.lineaporlinea.txt

}

function salirMenu()
{
echo "Fin del Programa"
}
### Main ###
opcionmenuppal=0
while test $opcionmenuppal -ne 26
do
    #Muestra el menu
    echo -e "0) Empaqueta y comprime los ficheros clave del proyecto\n"
    echo -e "1) Eliminar la instalación de mysql\n"
    echo -e "2) Crea la nueva ubicación \n"
    echo -e "3) Copiar ficheros proyecto Nueva Ubicacion \n"
    echo -e "4) Instalar MySql \n"
    echo -e "5) Crear usuario Base de Datos \n"
    echo -e "6) Crear Base de Datos \n"
    echo -e "7) Ejecutar Entorno Virtual \n"
    echo -e "8) Instalar librerias Entorno Virtual \n"
    echo -e "9) Probar todo con servidor de desarrollo de Flask \n"
    echo -e "10) Instalar NGINX \n"
    echo -e "11) Arrancar NGINX \n"
    echo -e "12) Testear puertos NGINX \n"
    echo -e "13) Visualizar Index \n"
    echo -e "14) Personalizar Index \n"
    echo -e "15) Instalar Gunicorn \n"
    echo -e "16) Configurar Gunicorn \n"
    echo -e "17) Pasar propiedad y permisos \n"
    echo -e "18) Crear Servicio Systemd FormularioCitas \n"
    echo -e "19) Configurar Nginx como Proxy Inverso \n"
    echo -e "20) Cargar Ficheros de Configuracion de Nginx \n"
    echo -e "21) Rearrancar Nginx \n"
    echo -e "22) Testear VirtualHost \n"
    echo -e "23) Ver Logs de Nginx \n"
    echo -e "24) Copiar Servidor Remoto \n"
    echo -e "25) Controlar Intentos de Conexion SSH \n"
    echo -e "26) salir del Menu \n"
    	read -p "Elige una opcion:" opcionmenuppal
    case $opcionmenuppal in
        0) empaquetaycomprimeFicherosProyecto;;
        1) eliminarMySQL;;
   	2) crearNuevaUbicacion;;
   	3) copiarFicherosProyectoNuevaUbicacion;;
   	4) instalarMySQL;;
   	5) crear_usuario_basesdedatos;;
   	6) crearbasededatos;;
   	7) ejecutarEntornoVirtual;;
   	8) instalarLibreriasEntornoVirtual;;
   	9) probandotodoconservidordedesarrollodeflask;;
   	10) instalarNGINX;;
   	11) ArrancarNGINX;;
   	12) TestearPuertosNGINX;;
   	13) visualizarIndex;;
   	14) personalizarIndex;;
   	15) instalarGunicorn;;
   	16) configurarGunicorn;;
   	17) pasarPropiedadyPermisos;;
   	18) crearServicioSystemdFormularioCitas;;
   	19) configurarNginxProxyInverso;;
   	20) cargarFicherosConfiguracionNginx;;
   	21) rearrancarNginx;;
   	22) testearVirtualHost;;
   	23) verNginxLogs;;
   	24) copiarServidorRemoto;;
   	25) controlarIntentosConexionSSH;;
   	26) salirMenu;;
   	*) ;;
    esac
done

exit 0

