# Embedding Hex Apps in Salesforce

Hex published apps can be embedded into Salesforce using two primary approaches, both utilizing iFrames within VisualForce pages.

## Embedding Methods

### Private Embedding
Private embedding uses [private embedding functionality](https://learn.hex.tech/docs/share-insights/embedding/public-and-private-embedding#private-embedding) to display Hex apps directly within Salesforce. This method:

- Passes data from Salesforce to Hex using [URL parameters](https://learn.hex.tech/docs/share-insights/apps/publish-and-share-apps#manually-specify-input-parameter-values-as-url-parameters)
- Modifies [user input parameters](https://learn.hex.tech/docs/explore-data/cells/input-cells/input-cells-introduction#add-an-input-cell) in the Hex project
- Initially prompts users to [login to Hex](https://learn.hex.tech/docs/administration/sso)

### Signed Embedding
Signed embedding uses [signed embedding functionality](https://learn.hex.tech/docs/share-insights/embedding/signed-embedding) for enhanced security. This method:

- Passes variables from Salesforce to Hex via the [hexUserAttributes object](https://learn.hex.tech/docs/api/api-reference#operation/CreatePresignedUrl)
- Uses a Salesforce Apex Controller to send API requests to Hex
- Generates single-use private URLs for secure access

## Setup Instructions

### Private Embedding Setup

1. **Create VisualForce Page**
   - Copy the `HexPrivateEmbed.page` template
   - Replace the Hex URL placeholder with your published app URL

2. **Add to Salesforce**
   - Add the VisualForce page to the Account page in Salesforce

### Signed Embedding Setup

1. **Create Apex Class**
   - Copy the `HexEmbeddingControllerDynamic.cls` template
   - Replace all placeholders with your specific values

2. **Create VisualForce Page**
   - Copy the `HexSignedEmbed.page` template
   - Replace all placeholders with your specific values

3. **Add to Salesforce**
   - Add the VisualForce page to the Account page in Salesforce

## Required Salesforce Configuration

### Remote Site Settings
For HTTP callouts from Apex, configure the following remote sites:

**Setup → Remote Site Settings → New Remote Site**

Add these URLs:
- `https://app.hex.tech`
- `https://static.hex.site` (for CSS/assets)
- `https://accounts.google.com` (for Google authentication)

### Content Security Policy (CSP)
If your organization has strict CSP policies, add trusted sites:

**Setup → CSP Trusted Sites → New Trusted Site**

Add these URLs:
- `https://app.hex.tech`
- `https://static.hex.site`
- `https://accounts.google.com`

## Summary

Both embedding methods provide flexible integration options between Hex and Salesforce, with private embedding offering simpler setup and signed embedding providing enhanced security through API-generated URLs. Choose the method that best fits your organization's security requirements and technical capabilities.
