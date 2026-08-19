/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDStaticResources.
* @Why   : Handles all the static and hardcoded text which are referenced in Apex classes (No methods only variables).
* @When  : 23-MAR-2017.
* @Where : From ADDSearchController class, ADDUtil class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID            Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				  23-MAR-2017			 Work ID / Case ID          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                   13-AUG-2020            Code Audit                 Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDStaticResources { 
    
    // Static variable declaration 
    
    public final static String inquiryCustomerResponseKeyValue = 'Inquiry_Customer_Response';
    public final static String complaintCustomerResponseKeyValue = 'Complaint_Customer_Response';
    public final static Boolean executingThroughInvokable = false;
    public final static String investigationRuleKeyValue = 'PRODEVAL_WORKFLOW';
    public final static String investigationAMDRuleKeyValue = 'PRODEVAL_WORKFLOW_AMD';
    public final static String assessmentRuleKeyValue = 'MEDICAL_EVALUATION_WORKFLOW';
    public static Map<String,String> recordTypesWithKeyValue = 
        new Map<String,String>{'Service' => 'SERVICE_WORKFLOW','Inquiry' => 'INQUIRY_WORKFLOW',
        'Complaint' => 'COMPLAINT_WORKFLOW'};
        
    public static Set<String> EXCLUDEOBJECTSET = new Set<String> {
        'CMPL123CME__CVR__c', 'CMPL123CME__Complaint_Investigation__c', 'CMPL123CME__HHE__c',
        'CMPL123CME__MDR__c', 'CMPL123CME__Repair__c', 'CMPL123CME__TGA__c', 'Regulatory_Reporting__c',
        'CMPL123__Contact__c', 'Ticket_Product_Evaluation_Investigation__c'
    };
    
    public static Set<String> INCLUDEDATATYPES = new Set<String>{
        'STRING', 'TEXTAREA', 'PHONE', 'FAX', 'DATE', 'DATETIME', 'EMAIL', 'PICKLIST', 'BOOLEAN', 'REFERENCE'
    };
    
    public static Map<String, Integer> INVSTATUSMAP = 
        new Map<String, Integer>{'Assess' => 1, 'In Process-Evaluation' => 2,
        'In Process-Investigation' => 3, 'Conclude' => 4, 'PE Review' => 5
    };
}