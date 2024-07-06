RESOURCE_GROUP="frontend-cop-demo"
STORAGE_ACCOUNT="frontendcopdemo"

echo "Checking if resource group $RESOURCE_GROUP exists"
if [ $(az group exists --name $RESOURCE_GROUP) = false ]; then
    echo "Creating resource group $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION
else
    echo "Resource group $RESOURCE_GROUP already exists"
fi

cd ../dist
echo "Creating storage account $STORAGE_ACCOUNT in resource group $RESOURCE_GROUP"
az storage account create --name $STORAGE_ACCOUNT --kind StorageV2 --resource-group $RESOURCE_GROUP --sku Standard_LRS

echo "Enabling static website on storage account $STORAGE_ACCOUNT"
az storage blob service-properties update --account-name $STORAGE_ACCOUNT --static-website --index-document index.html

echo "Uploading files to storage account $STORAGE_ACCOUNT"
az storage blob upload-batch -s . -d '$web' --account-name $STORAGE_ACCOUNT

echo "Static website URL: "
az storage account show --name $STORAGE_ACCOUNT --query "primaryEndpoints.web" --output tsv