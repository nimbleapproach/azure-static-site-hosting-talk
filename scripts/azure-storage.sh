RESOURCE_GROUP="frontend-cop-demo"
STORAGE_ACCOUNT="frontendcopdemo"
LOCATION="uksouth"

echo "Checking if resource group $RESOURCE_GROUP exists"
if [ $(az group exists --name $RESOURCE_GROUP) = false ]; then
    echo "Creating resource group $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION
else
    echo "Resource group $RESOURCE_GROUP already exists"
fi

echo "Checking if storage account $STORAGE_ACCOUNT exists"
ACCOUNT_EXISTS=$(az storage account check-name --name $STORAGE_ACCOUNT --query 'nameAvailable' -o tsv)
if [ "$ACCOUNT_EXISTS" = "true" ]; then
    echo "Creating storage account $STORAGE_ACCOUNT in resource group $RESOURCE_GROUP"
    az storage account create --name $STORAGE_ACCOUNT --kind StorageV2 --resource-group $RESOURCE_GROUP --sku Standard_LRS
else
    echo "Storage account $STORAGE_ACCOUNT already exists"
fi

echo "Checking if static website is enabled on storage account $STORAGE_ACCOUNT"
STATIC_WEBSITE_ENABLED=$(az storage blob service-properties show --account-name $STORAGE_ACCOUNT --query 'staticWebsite.enabled' -o tsv)
if [ "$STATIC_WEBSITE_ENABLED" != "true" ]; then
    echo "Enabling static website on storage account $STORAGE_ACCOUNT"
    az storage blob service-properties update --account-name $STORAGE_ACCOUNT --static-website --index-document index.html
else
    echo "Static website already enabled on storage account $STORAGE_ACCOUNT"
fi

cd ../dist
echo "Uploading files to storage account $STORAGE_ACCOUNT"
az storage blob upload-batch -s . -d '$web' --account-name $STORAGE_ACCOUNT

echo "Static website URL: "
az storage account show --name $STORAGE_ACCOUNT --query "primaryEndpoints.web" --output tsv