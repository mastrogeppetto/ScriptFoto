install:
	chmod u+x *.sh
	cp *.sh ~/bin/
	sudo cp watch_archived.sh /usr/local/bin/
	sudo cp watch-archived.service /etc/systemd/system
	sudo systemctl daemon-reexec
	sudo systemctl daemon-reload
	sudo systemctl enable --now watch-archived.service
	sudo systemctl status watch-archived.service
