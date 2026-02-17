ENV=dev
PROJECT_ID=trueclaw-487721
GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/application_default_credentials.json

refresh:
	terraform refresh  -var="project=$(PROJECT_ID)"

plan:
	terraform plan -var="project=$(PROJECT_ID)"

apply:
	terraform apply -var="project=$(PROJECT_ID)"

auth:
	gcloud auth login
	gcloud auth application-default login
