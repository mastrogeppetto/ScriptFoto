install:
	sudo cp 98-messaggio-per-gruppo-foto /etc/update-motd.d/
	sudo chmod +x /etc/update-motd.d/98-messaggio-per-gruppo-foto
	pandoc README.md -o README.pdf --pdf-engine=wkhtmltopdf
