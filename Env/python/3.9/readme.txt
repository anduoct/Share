pip install --no-index --find-links=./whl -r ./requirements.txt

pip freeze > .\requirements.txt

pip download -d .\whl\ -r requirements.txt