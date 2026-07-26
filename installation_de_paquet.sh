#Installation de paquet avec sauvegarde dans un fichier du nom de paquet
clear
echo -n "Nom du paquet: "
read paquet

sudo apt update -y | sudo apt upgrade -y | sudo apt autoremove -y

sudo apt install $paquet

echo $paquet >> /home/johan/Documents/list_paquet/liste_paquet.txt
