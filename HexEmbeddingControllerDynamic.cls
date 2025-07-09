public class HexEmbeddingControllerDynamic {
    // Constants for Hex API integration
    private static final String BASE_HEX_API_URL = 'https://app.hex.tech/api/v1';
    private static final String TOKEN = 'YOUR_HEX_API_TOKEN_HERE';
    private static final String PROJECT_ID = 'YOUR_HEX_PROJECT_ID_HERE';
    
    // Properties exposed to the Visualforce page
    public String hexUrl { get; set; }          // The generated embedded URL from Hex
    public String errorMessage { get; set; }    // Error message to display if something goes wrong
    public Boolean isLoading { get; set; }      // Loading state for UI feedback
    
    // Property to hold the current account ID from the page context
    public String accountId { get; set; }
    
    // Default constructor - used when controller is instantiated without parameters
    public HexEmbeddingControllerDynamic() {
        isLoading = false;
        // Get account ID from page parameter or standard controller
        accountId = getAccountIdFromPage();
        // Immediately generate the Hex URL when controller is created
        generateHexUrl();
    }
    
    // Constructor that accepts account ID (for when using with standard controller)
    // This is used when the Visualforce page has standardController="Account"
    public HexEmbeddingControllerDynamic(ApexPages.StandardController controller) {
        isLoading = false;
        // Try to get the account ID from the standard controller's record
        if (controller.getRecord() != null) {
            accountId = controller.getRecord().Id;
        } else {
            // Fallback to getting it from page parameters
            accountId = getAccountIdFromPage();
        }
        // Generate the Hex URL immediately
        generateHexUrl();
    }
    
    // Method to extract account ID from URL parameters
    private String getAccountIdFromPage() {
        // Try to get from the 'id' parameter first (most common)
        String pageAccountId = ApexPages.currentPage().getParameters().get('id');
        
        // If not found in 'id' parameter, try 'accountId' parameter
        if (String.isBlank(pageAccountId)) {
            pageAccountId = ApexPages.currentPage().getParameters().get('accountId');
        }
        
        // Validate that it's actually an Account ID (Salesforce Account IDs start with '001')
        if (String.isNotBlank(pageAccountId) && pageAccountId.startsWith('001')) {
            return pageAccountId;
        }
        
        // Return null if no valid account ID found
        return null;
    }
    
    // Main method that creates an embedded URL from Hex.tech for the current account
    public void generateHexUrl() {
        // Set loading state and clear previous results
        isLoading = true;
        errorMessage = null;
        hexUrl = null;
        
        try {
            // Gather user information (current Salesforce user)
            Map<String, Object> userInfo = getCurrentUserInfo();
            // Gather account information (the account being viewed)
            Map<String, Object> accountInfo = getCurrentAccountInfo();
            
            // Debug logging to help troubleshoot issues
            System.debug('UserInfo retrieved: ' + JSON.serialize(userInfo));
            System.debug('AccountInfo retrieved: ' + JSON.serialize(accountInfo));
            
            // Create a map of user attributes that will be passed to Hex
            // These attributes can be used within Hex for filtering, personalization, etc.
            Map<String, String> hexUserAttributes = new Map<String, String>{
                'userId' => String.valueOf(userInfo.get('userId')),
                'userEmail' => String.valueOf(userInfo.get('userEmail')),
                'userName' => String.valueOf(userInfo.get('userName')),
                'accountId' => String.valueOf(accountInfo.get('accountId')),
                'accountName' => String.valueOf(accountInfo.get('accountName')),
                'accountType' => String.valueOf(accountInfo.get('accountType')),
                'testVariable' => 'dummy_value_123',                    // Test variable for debugging
                'timestamp' => String.valueOf(System.now().getTime())   // Current timestamp
            };
            
            // Add userRole if it exists (some users might not have roles)
            if (userInfo.get('userRole') != null) {
                hexUserAttributes.put('userRole', String.valueOf(userInfo.get('userRole')));
            }
            
            System.debug('Final hexUserAttributes: ' + JSON.serialize(hexUserAttributes));
            
            // Create the request body for the Hex API call
            Map<String, Object> requestBody = new Map<String, Object>{
                'hexUserAttributes' => hexUserAttributes,           // User context data
                'scope' => new List<String>{'EXPORT_PDF', 'EXPORT_CSV'}, // Permissions for the embedded app
                'inputParameters' => new Map<String, Object>(),     // Additional parameters (empty for now)
                'expiresIn' => '30000',                            // URL expiration time in seconds
                'displayOptions' => new Map<String, Object>{        // UI customization options
                    'theme' => 'light',
                    'noEmbedFooter' => true,                       // Hide Hex footer
                    'noEmbedOutline' => true,                      // Hide outline panel
                    'noEmbedBasePadding' => true                   // Remove default padding
                },
                'testMode' => false                                // Set to true for testing
            };
            
            // Set up the HTTP request to Hex API
            HttpRequest req = new HttpRequest();
            req.setEndpoint(BASE_HEX_API_URL + '/embedding/createPresignedUrl/' + PROJECT_ID);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + TOKEN);
            req.setHeader('Content-Type', 'application/json');
            
            // Use JSONGenerator for precise JSON control (ensures proper formatting)
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            
            // Build hexUserAttributes object in JSON
            gen.writeFieldName('hexUserAttributes');
            gen.writeStartObject();
            for (String key : hexUserAttributes.keySet()) {
                gen.writeStringField(key, hexUserAttributes.get(key));
            }
            gen.writeEndObject();
            
            // Build scope array in JSON
            gen.writeFieldName('scope');
            gen.writeStartArray();
            gen.writeString('EXPORT_PDF');
            gen.writeString('EXPORT_CSV');
            gen.writeEndArray();
            
            // Build empty inputParameters object
            gen.writeFieldName('inputParameters');
            gen.writeStartObject();
            gen.writeEndObject();
            
            // Add expiresIn as string (API expects string, not number)
            gen.writeStringField('expiresIn', '30000');
            
            // Build displayOptions object
            gen.writeFieldName('displayOptions');
            gen.writeStartObject();
            gen.writeStringField('theme', 'light');
            gen.writeBooleanField('noEmbedFooter', true);
            gen.writeBooleanField('noEmbedOutline', true);
            gen.writeBooleanField('noEmbedBasePadding', true);
            gen.writeEndObject();
            
            // Add testMode boolean
            gen.writeBooleanField('testMode', false);
            
            gen.writeEndObject();
            
            // Get the JSON string and set it as the request body
            String requestBodyJson = gen.getAsString();
            req.setBody(requestBodyJson);
            req.setTimeout(60000); // 60 second timeout
            
            // Debug logging for troubleshooting
            System.debug('Request URL: ' + req.getEndpoint());
            System.debug('Request Body JSON: ' + requestBodyJson);
            
            // Make the actual HTTP callout to Hex API
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // Log the response for debugging
            System.debug('Response Status: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
            
            // Check if the API call was successful
            if (res.getStatusCode() == 200) {
                // Parse the JSON response and extract the URL
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                hexUrl = (String) responseData.get('url');
                System.debug('Generated Hex URL: ' + hexUrl);
            } else {
                // Handle API errors
                System.debug('API Error - Status: ' + res.getStatusCode());
                System.debug('API Error - Body: ' + res.getBody());
                errorMessage = 'Error: ' + res.getStatusCode() + ' - ' + res.getBody();
            }
            
        } catch (Exception e) {
            // Handle any exceptions that occur during the process
            System.debug('Exception in generateHexUrl: ' + e.getMessage());
            System.debug('Exception stack trace: ' + e.getStackTraceString());
            errorMessage = 'Exception occurred: ' + e.getMessage();
        } finally {
            // Always set loading to false, regardless of success or failure
            isLoading = false;
        }
    }
    
    // Method to refresh the URL (can be called from Visualforce page)
    public void refreshUrl() {
        generateHexUrl();
    }
    
    // Method to get current user info from Salesforce
    public Map<String, Object> getCurrentUserInfo() {
        try {
            Id currentUserId = UserInfo.getUserId();
            
            // Query the User object to get detailed information
            User currentUser = [
                SELECT Id, Name, Email, UserRole.Name, Profile.Name, UserType
                FROM User 
                WHERE Id = :currentUserId
            ];
            
            // Return a map with user details
            return new Map<String, Object>{
                'userId' => currentUser.Id,
                'userName' => currentUser.Name,
                'userEmail' => currentUser.Email,
                'userRole' => currentUser.UserRole?.Name,       // Safe navigation operator
                'userType' => currentUser.UserType,
                'profileName' => currentUser.Profile?.Name      // Safe navigation operator
            };
            
        } catch (Exception e) {
            // Fallback to UserInfo methods if SOQL query fails
            System.debug('Error in getCurrentUserInfo: ' + e.getMessage());
            
            return new Map<String, Object>{
                'userId' => UserInfo.getUserId(),
                'userName' => UserInfo.getName(),
                'userEmail' => UserInfo.getUserEmail(),
                'userRole' => null,
                'userType' => UserInfo.getUserType(),
                'profileName' => null
            };
        }
    }
    
    // Method to get account info from the current page context
    public Map<String, Object> getCurrentAccountInfo() {
        try {
            // Check if we have an account ID to work with
            if (String.isBlank(accountId)) {
                System.debug('No account ID found in page context');
                return new Map<String, Object>{
                    'accountId' => null,
                    'accountName' => null,
                    'accountType' => null
                };
            }
            
            // Query the Account object to get detailed account information
            Account currentAccount = [
                SELECT Id, Name, Type, Industry, BillingCity, BillingState, BillingCountry
                FROM Account 
                WHERE Id = :accountId
                LIMIT 1
            ];
            
            System.debug('Current Account Data: ' + JSON.serialize(currentAccount));
            
            // Return a map with account details
            return new Map<String, Object>{
                'accountId' => currentAccount.Id,
                'accountName' => currentAccount.Name,
                'accountType' => currentAccount.Type,
                'accountIndustry' => currentAccount.Industry,
                'accountCity' => currentAccount.BillingCity,
                'accountState' => currentAccount.BillingState,
                'accountCountry' => currentAccount.BillingCountry
            };
            
        } catch (Exception e) {
            // Handle errors (e.g., account not found, no access permissions)
            System.debug('Error in getCurrentAccountInfo: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            
            // Return minimal information if query fails
            return new Map<String, Object>{
                'accountId' => accountId,
                'accountName' => 'Unknown Account',
                'accountType' => null
            };
        }
    }
    
    // Helper method for testing - gets the account name for the current page
    public String getAccountNameForCurrentPage() {
        Map<String, Object> accountInfo = getCurrentAccountInfo();
        return (String) accountInfo.get('accountName');
    }
}
