clear
echo " "
echo " ========================================"
echo " ########################################"
echo " ========================================"
echo " "
#VARIABLE---------------------------------------
rouge='\033[0;31m'
blanc='\033[0;37m'
nc='\033[0m'
#-----------------------------------------------
echo -e " ${blanc}1.Installation${nc}"
echo " "

echo -n -e " ${blanc}Choix de la fonction :${nc} "
read choix
echo " " 
#echo $choix

case $choix in
	1)
		/home/johan/script/installation_de_paquet.sh ;;
	*)
		echo -e " ${rouge}erreur${nc}";;
esac
