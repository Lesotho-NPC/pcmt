@javascript
Feature: Access FHIR InventoryItem Resource

    Scenario: Un authenticated user cannot access InventoryItem resource

    
    Scenario: Accessing InventoryItem without authentication
        Given I am a user without access to the FHIR server
        When I send a GET request to "/api/fhir/r5/InventoryItem/b7984023-6ce1-498a-b694-a0cd5cce6588"
        Then the response status code should be "401"
    
    Scenario: Accessing InventoryItem with valid authentication
        Given I am authenticated with valid credentials
        When I send a GET request to "/#/configuration/attribute/ACTIVE_INGREDIENT/edit"
        Then the response should be able to access authenticated page
