# Variables
RESOURCE_GROUP="frontend-cop-demo"
LOCATION="uksouth"
ACR_NAME="frontendcopdemoacr"
IMAGE_NAME="frontend-cop-demo:latest"
CONTAINER_APP_ENVIRONMENT="frontend-cop-demo-cae"
USER_ASSIGNED_IDENTITY_NAME="frontend-cop-demo-acr-identity"
CONTAINER_APP_NAME="frontend-cop-demo-ca"

# Check if the resource group exists, create if it doesn't
echo "Checking if resource group $RESOURCE_GROUP exists"
if [ $(az group exists --name $RESOURCE_GROUP) = "false" ]; then
    echo "Creating resource group $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION
else
    echo "Resource group $RESOURCE_GROUP already exists"
fi

# Check if the Azure Container Registry exists, create if it doesn't
echo "Checking if Azure Container Registry $ACR_NAME exists"
ACR_EXISTS=$(az acr list --query "[?name=='$ACR_NAME'].name" -o tsv --resource-group $RESOURCE_GROUP)
if [ -z "$ACR_EXISTS" ]; then
    echo "Creating Azure Container Registry $ACR_NAME"
    az acr create --name $ACR_NAME --resource-group $RESOURCE_GROUP --sku Basic --admin-enabled true
else
    echo "Azure Container Registry $ACR_NAME already exists"
fi

# Build and push Docker image to ACR
echo "Building Docker image..."
docker build --platform=linux/amd64 -t $ACR_NAME.azurecr.io/$IMAGE_NAME ../
echo "Logging into ACR..."
az acr login --name $ACR_NAME
echo "Pushing Docker image to ACR..."
docker push $ACR_NAME.azurecr.io/$IMAGE_NAME

# Check if the User-Assigned Identity exists, create if it doesn't
echo "Checking if User-Assigned Identity $USER_ASSIGNED_IDENTITY_NAME exists"
IDENTITY_EXISTS=$(az identity list --query "[?name=='$USER_ASSIGNED_IDENTITY_NAME'].name" -o tsv --resource-group $RESOURCE_GROUP)
if [ -z "$IDENTITY_EXISTS" ]; then
    echo "Creating User-Assigned Identity $USER_ASSIGNED_IDENTITY_NAME"
    az identity create --name $USER_ASSIGNED_IDENTITY_NAME --resource-group $RESOURCE_GROUP
else
    echo "User-Assigned Identity $USER_ASSIGNED_IDENTITY_NAME already exists"
fi

sleep 30

# Assign role to User-Assigned Identity to pull images from ACR
IDENTITY_ID=$(az identity show --name $USER_ASSIGNED_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query id -o tsv)
IDENTITY_CLIENT_ID=$(az identity show --name $USER_ASSIGNED_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query clientId -o tsv)
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query id -o tsv)
# Check if the role assignment already exists
echo "Checking if role assignment exists for User-Assigned Identity"
ROLE_ASSIGNMENT_EXISTS=$(az role assignment list --assignee $IDENTITY_CLIENT_ID --role acrpull --scope $ACR_ID --query [].id -o tsv)
if [ -z "$ROLE_ASSIGNMENT_EXISTS" ]; then
    echo "Creating role assignment for User-Assigned Identity to pull images from ACR"
    az role assignment create --assignee $IDENTITY_CLIENT_ID --role acrpull --scope $ACR_ID
else
    echo "Role assignment for User-Assigned Identity already exists"
fi

# Check if the Container App Environment exists, create if it doesn't
echo "Checking if Container App Environment $CONTAINER_APP_ENVIRONMENT exists"
ENVIRONMENT_EXISTS=$(az containerapp env list --query "[?name=='$CONTAINER_APP_ENVIRONMENT'].name" -o tsv --resource-group $RESOURCE_GROUP)
if [ -z "$ENVIRONMENT_EXISTS" ]; then
    echo "Creating Container App Environment $CONTAINER_APP_ENVIRONMENT"
    az containerapp env create --name $CONTAINER_APP_ENVIRONMENT --resource-group $RESOURCE_GROUP --location $LOCATION
else
    echo "Container App Environment $CONTAINER_APP_ENVIRONMENT already exists"
fi

# Create Container App with the Docker image
echo "Creating Container App $CONTAINER_APP_NAME"
az containerapp create --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --environment $CONTAINER_APP_ENVIRONMENT --image $ACR_NAME.azurecr.io/$IMAGE_NAME --registry-server $ACR_NAME.azurecr.io --registry-identity $IDENTITY_ID --ingress external --target-port 80

echo "Container App $CONTAINER_APP_NAME has been created successfully."

# Get the FQDN of the Container App
FQDN=$(az containerapp show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP -o json | jq .properties.configuration.ingress.fqdn -r)
echo "Container App $CONTAINER_APP_NAME is available at $FQDN"