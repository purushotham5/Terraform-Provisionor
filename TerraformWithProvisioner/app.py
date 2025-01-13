# to install python packages or flask on the ec2 use this bellow following commands 
# # First Login to the ec2 instances then follow 
# sudo apt update -y
# sudo apt-get install -y python3-flask
# sudo python3 app.py { here it will run the port 80, then go the ec2 instaces open the public ip address in new tab we will get the python code output }


from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello, Terraform!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
