# Kickstarting Application Development with Gemini Code Assist: Challenge Lab || GSP527 🚀 

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service. The aim is to enhance your learning experience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">

## Task-2 `backend/index.test.ts`:

```bash
// Gemini: Write a test for the /outofstock endpoint to verify it returns a status 200 and a list of 2 items.
```
```bash
cd cymbal-superstore/backend
npm install
npm run test
```
## Task-3 `backend/index.ts`:
```bash
// This endpoint should return all out-of-stock products.
```
```bash
npm run test
```
## Task-4 `functions/index.js`:
```bash
const functions = require('@google-cloud/functions-framework');
const {Firestore} = require('@google-cloud/firestore');

// Create a Firestore client
const firestore = new Firestore();

// Create a Cloud Function that will be triggered by an HTTP request
functions.http('newproducts', async (req, res) => {
  // Get the products from Firestore
  const products = await firestore.collection('inventory').where('timestamp', '>', new Date(Date.now() - 604800000)).get();

  initFirestoreCollection();

  // Create an array of products
  const productsArray = [];
  products.forEach((product) => {
    const p = {
      id: product.id,
      name: product.data().name + ' (' + product.data().quantity + ')',
      price: product.data().price,
      quantity: product.data().quantity,
      imgfile: product.data().imgfile,
      timestamp: product.data().timestamp,
      actualdateadded: product.data().actualdateadded,
    };
    productsArray.push(p);
  });

  // Send the products array to the client
  res.set('Access-Control-Allow-Origin', '*');
  res.send(productsArray);
});

// Create a Cloud Function for out-of-stock products
functions.http('outofstock', async (req, res) => {
  // Query Firestore for products with quantity 0 (out of stock)
  const snapshot = await firestore.collection('inventory').where('quantity', '==', 0).get();
  const outOfStock = [];
  snapshot.forEach(doc => {
    outOfStock.push({
      id: doc.id,
      name: doc.data().name,
      price: doc.data().price,
      quantity: doc.data().quantity,
      imgfile: doc.data().imgfile,
      timestamp: doc.data().timestamp,
      actualdateadded: doc.data().actualdateadded
    });
  });
  res.set('Access-Control-Allow-Origin', '*');
  res.status(200).json(outOfStock);
});

// ------------------- ------------------- ------------------- ------------------- -------------------
// HELPERS -- SEED THE INVENTORY DATABASE (PRODUCTS)
// ------------------- ------------------- ------------------- ------------------- -------------------

// This will overwrite products in the database - this is intentional, to keep the date-added fresh.
function initFirestoreCollection() {
  const oldProducts = [
    "Apples",
    "Bananas",
    "Milk",
    "Whole Wheat Bread",
    "Eggs",
    "Cheddar Cheese",
    "Whole Chicken",
    "Rice",
    "Black Beans",
    "Bottled Water",
    "Apple Juice",
    "Cola",
    "Coffee Beans",
    "Green Tea",
    "Watermelon",
    "Broccoli",
    "Jasmine Rice",
    "Yogurt",
    "Beef",
    "Shrimp",
    "Walnuts",
    "Sunflower Seeds",
    "Fresh Basil",
    "Cinnamon",
  ];
  // Add "old" products to Firestore
  for (let i = 0; i < oldProducts.length; i++) {
    const oldProduct = {
      name: oldProducts[i],
      price: Math.floor(Math.random() * 10) + 1,
      quantity: Math.floor(Math.random() * 500) + 1,
      imgfile: "product-images/" + oldProducts[i].replace(/\s/g, "").toLowerCase() + ".png",
      timestamp: new Date(Date.now() - Math.floor(Math.random() * 31536000000) - 7776000000),
      actualdateadded: new Date(Date.now()),
    };
    console.log("Adding (or updating) product in firestore: " + oldProduct.name);
    addOrUpdateFirestore(oldProduct);
  }
  // Add recent products
  const recentProducts = [
    "Parmesan Crisps",
    "Pineapple Kombucha",
    "Maple Almond Butter",
    "Mint Chocolate Cookies",
    "White Chocolate Caramel Corn",
    "Acai Smoothie Packs",
    "Smores Cereal",
    "Peanut Butter and Jelly Cups",
  ];
  for (let j = 0; j < recentProducts.length; j++) {
    const recent = {
      name: recentProducts[j],
      price: Math.floor(Math.random() * 10) + 1,
      quantity: Math.floor(Math.random() * 100) + 1,
      imgfile: "product-images/" + recentProducts[j].replace(/\s/g, "").toLowerCase() + ".png",
      timestamp: new Date(Date.now() - Math.floor(Math.random() * 518400000) + 1),
      actualdateadded: new Date(Date.now()),
    };
    console.log("Adding (or updating) product in firestore: " + recent.name);
    addOrUpdateFirestore(recent);
  }
  // Add recent products that are out of stock
  const recentProductsOutOfStock = ["Wasabi Party Mix", "Jalapeno Seasoning"];
  for (let k = 0; k < recentProductsOutOfStock.length; k++) {
    const oosProduct = {
      name: recentProductsOutOfStock[k],
      price: Math.floor(Math.random() * 10) + 1,
      quantity: 0,
      imgfile: "product-images/" + recentProductsOutOfStock[k].replace(/\s/g, "").toLowerCase() + ".png",
      timestamp: new Date(Date.now() - Math.floor(Math.random() * 518400000) + 1),
      actualdateadded: new Date(Date.now()),
    };
    console.log("Adding (or updating) out of stock product in firestore: " + oosProduct.name);
    addOrUpdateFirestore(oosProduct);
  }
}

// Helper - add Firestore doc if not exists, otherwise update
function addOrUpdateFirestore(product) {
  firestore
    .collection("inventory")
    .where("name", "==", product.name)
    .get()
    .then((querySnapshot) => {
      if (querySnapshot.empty) {
        firestore.collection("inventory").add(product);
      } else {
        querySnapshot.forEach((doc) => {
          firestore.collection("inventory").doc(doc.id).update(product);
        });
      }
    });
}
```
```bash
cd cymbal-superstore/functions
```
**⚠️Change `REGION` of below As per your lab Instruction**
```bash
gcloud functions deploy outofstock --runtime=nodejs20 --trigger-http --entry-point=outofstock --region=us-central1 --allow-unauthenticated
```
## Task-5 Create an `API Gateway` to expose the `outofstock Cloud Function`
Step 1: Set Environment Variables
```bash
export CONFIG_ID=outofstock-api-config
export API_ID=outofstock-api
export GATEWAY_ID=store
export OPENAPI_SPEC=outofstock.yaml
```
Step 2: Create the gateway Directory and OpenAPI Spec
```bash
mkdir gateway
cd gateway
touch outofstock.yaml
```
Step 3: Generate OpenAPI Specification
```bash
swagger: '2.0'
info:
  title: OutOfStock API
  version: 1.0.0
host: us-central1-yourproject.cloudfunctions.net
schemes:
  - https
paths:
  /outofstock:
    get:
      summary: Get out of stock products
      operationId: outofstock
      x-google-backend:
        address: https://us-central1-yourproject.cloudfunctions.net/outofstock
      responses:
        '200':
          description: Successful response
          schema:
            type: array
            items:
              type: object
security: []  # This allows unauthenticated access; or replace with proper API key security
```
**⚠️Replace `REGION-PROJECT_ID` with your actual project ID**
Step 4: Enable API Gateway Service
```bash
gcloud services enable apigateway.googleapis.com
```
Step 5: Create API and API Configuration
```bash
gcloud api-gateway apis create $API_ID --display-name="Out of Stock API"
gcloud api-gateway api-configs create $CONFIG_ID --api=$API_ID --openapi-spec=outofstock.yaml --display-name="Out of Stock API Config"
```
Step 6: Create API Gateway & Verify and Test
```bash
gcloud api-gateway gateways create $GATEWAY_ID --api=$API_ID --api-config=$CONFIG_ID --location=us-central1
gcloud api-gateway gateways describe $GATEWAY_ID --location=us-central1
```
**⚠️Change `LOCATION` of above As per your lab Instruction**

</div>

---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  


