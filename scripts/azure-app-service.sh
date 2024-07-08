# Variables
RESOURCE_GROUP="frontend-cop-demo"
LOCATION="uksouth"
APP_SERVICE_PLAN="frontend-cop-demo-asp"
APP_NAME="frontend-cop-demo-app"

# Check if the resource group exists, create if it doesn't
echo "Checking if resource group $RESOURCE_GROUP exists"
if [ $(az group exists --name $RESOURCE_GROUP) = "false" ]; then
    echo "Creating resource group $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION
else
    echo "Resource group $RESOURCE_GROUP already exists"
fi

# Check if the App Service Plan exists, create if it doesn't
echo "Checking if App Service Plan $APP_SERVICE_PLAN exists"
APP_SERVICE_PLAN_EXISTS=$(az appservice plan list --query "[?name=='$APP_SERVICE_PLAN'].name" -o tsv)
if [ -z "$APP_SERVICE_PLAN_EXISTS" ]; then
    echo "Creating App Service Plan $APP_SERVICE_PLAN"
    az appservice plan create --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP --location $LOCATION --sku F1 --is-linux
else
    echo "App Service Plan $APP_SERVICE_PLAN already exists"
fi

# Check if the App Service App exists
echo "Checking if App Service App $APP_NAME exists"
APP_EXISTS=$(az webapp list --query "[?name=='$APP_NAME'].name" -o tsv --resource-group $RESOURCE_GROUP)
if [ -z "$APP_EXISTS" ]; then
    echo "Creating App Service App $APP_NAME"
    az webapp create --name $APP_NAME --plan $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP --runtime "NODE|20-lts"
    echo "App Service App $APP_NAME has been created"
else
    echo "App Service App $APP_NAME already exists"
fi

cd ../dist

# Deploy the app to the App Service App
az webapp up --location $LOCATION --name $APP_NAME --html -p $APP_SERVICE_PLAN -g $RESOURCE_GROUP --os-type Linux