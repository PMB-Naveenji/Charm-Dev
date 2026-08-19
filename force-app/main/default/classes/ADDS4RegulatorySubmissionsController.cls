/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDS4RegulatorySubmissionsController
* @Why   : Handles all the customization involved on submission detail
* @When  : 23-MAR-2017
* @Where : From ADDS4RegulatorySubmissions Page
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Admin                23-MAR-2017            Work ID / Case ID     Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Juneid               07-JUNE-2021             MIR Release         Implemened the logic for IVDD/IVDR.
*  --------------------------------------------------------------------------------------------------------------------------------------
       Juneid               20-SEP-2021             MIR Release        Updated Type of Report Vlaue 'Initial Report' to 'Initial'
*  --------------------------------------------------------------------------------------------------------------------------------------
       Dinesh Kumar         15-JAN-2024             CHaRM-R4           Updated the method "createSubmissions"
*  --------------------------------------------------------------------------------------------------------------------------------------
       Dinesh Kumar         06-SEP-2024             CHaRM-R5/IPDR 652           Updated the method "createSubmissions"
*  --------------------------------------------------------------------------------------------------------------------------------------
       Dinesh Kumar         26-DEC-2024             CHaRM-R6/IPDR 618           Updated the method "fetchSelectedSubmissions"
*  --------------------------------------------------------------------------------------------------------------------------------------
       Rohit Choudhary      24-FEB-2026             CHaRM-R8                Updated the method "createSubmissions" to add conditional parameter "GB MIR" 
																			as part of TWD changes. Now MIR can be generated for both EU and GB based on 
																			the Submission country. 
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ADDS4RegulatorySubmissionsController{
    
    private ApexPages.StandardController standardController;
    public Map<Id,Product_Ticket__c> productTicketMap {get;set;}
    public Map<String,List<String>> countryWithTypeMap {set;get;} 
    public String countryJSON {set;get;} 
    public String selectedProductIds{set;get;}
    public Boolean registeredSiteError{set;get;}
    public SET<String> registeredSiteProductError{set;get;}
    public String selectedCountries{set;get;}
    public Boolean isConfirmWindow{set;get;}
    public List<SubmissionDetail> submissionDetails{set;get;}
    public String defaultCountry{set;get;}
    public Set<String> defaultCoutries{set;get;}
    public String assessmentId{set;get;}
    String ticketId;
    Map<String, Country_Submission_Type__c> submissionCountryMap;
    Date initialAwarenessDate;
    Map<String, String> countryIdMap;
    CMPL123CME__Questionnaire__c currentQuestionnaire;
    private Boolean isDeath = false;
    //Code Changes for sprint4 start By : Chandu V
    Map<String,String> countryRepMap = new Map<String,String>();
     //Code Changes for sprint4 end By : Chandu V
     
 
    /**
* @Method       : constructor
* @Invoke       : From ADDS4RegulatorySubmissions Page
* @Description  : Initialize class members
* @Return       : N/A
* @Params       : ApexPages.StandardController standardController
**/      
    public ADDS4RegulatorySubmissionsController(ApexPages.StandardController standardController){
        isConfirmWindow = false;
        registeredSiteError = false;
        registeredSiteProductError = new set<String>();
        this.standardController = standardController;  
        submissionCountryMap = new Map<String, Country_Submission_Type__c>();
        countryIdMap = new Map<String, String>();
        defaultCoutries = new Set<String>();
        
        if(!Test.isRunningTest()){ 
            this.standardController.addFields(new List<String> {'Name', 'CMPL123CME__Complaint__c', 'Initial_Awareness_Date__c', 
                'CMPL123CME__Complaint__r.Country_of_origin__c', 'Adverse_Event__c', 
                'B2_Outcomes_attributed_to_AE__c', 'Initial_Follow_Up_Mfg_Analysis_New__c', 'Division__c'});
            currentQuestionnaire = (CMPL123CME__Questionnaire__c)standardController.getRecord();
            for(CMPL123CME__Questionnaire_Items__c qtemsList : [SELECT CMPL123CME__Questionnaire__c, Id, CMPL123CME__Answer__c, CMPL123CME__Question__c, CMPL123CME__Question_No__c FROM CMPL123CME__Questionnaire_Items__c WHERE CMPL123CME__Questionnaire__c =: currentQuestionnaire.Id AND CMPL123CME__Answer__c = 'Yes']){
                if(qtemsList.CMPL123CME__Question__c.contains('2a)')){
                    isDeath = true;
                }
                
            }
        } else {
            
            currentQuestionnaire = [SELECT Name, CMPL123CME__Complaint__c, Initial_Awareness_Date__c, 
                                    CMPL123CME__Complaint__r.Country_of_origin__c, Adverse_Event__c, 
                                    B2_Outcomes_attributed_to_AE__c,Initial_Follow_Up_Mfg_Analysis_New__c, Initial_Follow_Up_Mfg_Analysis__c, Division__c 
                                    FROM CMPL123CME__Questionnaire__c LIMIT 1];
            
        }   
        
        assessmentId = currentQuestionnaire.Id;
        ticketId = currentQuestionnaire.CMPL123CME__Complaint__c;
        initialAwarenessDate = currentQuestionnaire.Initial_Awareness_Date__c;
        if(currentQuestionnaire.CMPL123CME__Complaint__r.Country_of_origin__c != null){
            defaultCoutries.add(currentQuestionnaire.CMPL123CME__Complaint__r.Country_of_origin__c);
        }
        
        if(currentQuestionnaire.CMPL123CME__Complaint__c != null){
            productTicketMap = new Map< Id, Product_Ticket__c >();
            countryWithTypeMap = new Map<String,List<String>>();
            for(Product_Ticket__c productTicket : [SELECT Id, GTIN_Static__c, Product_Name__c, Product_List_Number__c , 
                                                   Likely_Cause__c, Product__r.Registered_Site__c , Product__r.IVDR_Registered_Site__c, 
                                                   Batch_Lot_Serial__c FROM Product_Ticket__c WHERE 
                                                   Event_Ticket__r.Id = :currentQuestionnaire.CMPL123CME__Complaint__c]){
                                                       productTicketMap.put(productTicket.Id, productTicket);
                                                   }
            
            for(Country__c country : [SELECT Id, Country_Code__c, Name, Division__c, Report_Type__c,
                                      AE_Submission_Required__c, Death_Submission_Required__c, Submission_Required__c,
                                      (SELECT Id, Name, Calendar_Days__c FROM Country_Submission_Types__r WHERE Active__c = true ORDER BY Calendar_Days__c DESC) 
                                      FROM Country__c WHERE Name != null AND Division__c =:currentQuestionnaire.Division__c AND Active__c = true]){
                                          if((country.AE_Submission_Required__c && currentQuestionnaire.Adverse_Event__c)
                                             || (country.Death_Submission_Required__c && currentQuestionnaire.B2_Outcomes_attributed_to_AE__c == 'Death') 
                                             || country.Submission_Required__c) {
                                                 defaultCoutries.add(country.Name);  
                                               
                                             }
                                             countryRepMap.put(country.Name, country.Report_Type__c); 
                                          List<String> submissionTypes = new List<String>();
                                          for(Country_Submission_Type__c subType : country.Country_Submission_Types__r){
                                              submissionTypes.add(subType.Name);
                                              submissionCountryMap.put(country.Name +'_'+ subType.Name, subType);    
                                          }
                                          countryWithTypeMap.put(country.Name, submissionTypes);
                                          countryJSON = JSON.serialize(countryWithTypeMap);
                                          countryIdMap.put(country.Name, country.Id);
                                      }
            defaultCountry = JSON.serialize(defaultCoutries);
        }
    }
    /**
* @Method       : fetchSelectedSubmissions
* @Invoke       : From ADDS4RegulatorySubmissions Page
* @Description  : Handles the submissions
* @Return       : N/A
* @Params       : N/A
**/     
    public void fetchSelectedSubmissions() {
        submissionDetails = new List<submissionDetail>();
        if(selectedProductIds != null && selectedCountries != null 
           && selectedProductIds != '' && selectedCountries != '') {
               for(String productId : selectedProductIds.split(';')){
                   if(productId != 'undefined'){
                       Product_Ticket__c prodTicket = productTicketMap.get(productId);
                       for(String countryWithType : selectedCountries.split(';')){
                           String countryName = countryWithType.split('-')[0];
                           String submissionType;
                           String submissionTypeId;//CHaRM R6
                           //Modified code for product backlog item 32937
                           if(!countryRepMap.isEmpty() && countryRepMap.containsKey(countryName))
                               submissionType=countryRepMap.get(countryName);
                           
                           //CHaRM R6: Updated the below code to process the USA country seperately as the country submission type of USA contains 30-day, 5-day
                           // value and need to process the data accordingly to create an emdr, MDI and MIR submission
                           if(countryName == 'USA'){
                               submissionType = submissionType + '('+countryWithType.split('-')[1]+'-'+countryWithType.split('-')[2]+')';
                               submissionTypeId = submissionCountryMap.get(countryWithType.split('-')[0]+'_'+countryWithType.split('-')[1]+'-'+countryWithType.split('-')[2]) != null 
                               ? submissionCountryMap.get(countryWithType.split('-')[0]+'_'+countryWithType.split('-')[1]+'-'+countryWithType.split('-')[2]).Id
                               : ''; 
                               
                                Decimal calendarDays = submissionCountryMap.get(countryWithType.split('-')[0]+'_'+countryWithType.split('-')[1]+'-'+countryWithType.split('-')[2]) != null 
                               ? submissionCountryMap.get(countryWithType.split('-')[0]+'_'+countryWithType.split('-')[1]+'-'+countryWithType.split('-')[2]).Calendar_Days__c
                               : 0;     
                               submissionDetails.add(new SubmissionDetail(true, countryName, submissionType, submissionTypeId, calendarDays,
                                                                          prodTicket.Product_Name__c, prodTicket.Product_List_Number__c, prodTicket.Batch_Lot_Serial__c, prodTicket.Likely_Cause__c,
                                                                          prodTicket.Id, prodTicket.GTIN_Static__c, prodTicket.Product__r.Registered_Site__c,'', prodTicket.Product__r.IVDR_Registered_Site__c
                                                                         ));
                           }
                           else{
                               submissionType = submissionType + '('+countryWithType.split('-')[1]+')';
                               submissionTypeId = submissionCountryMap.get(countryWithType.split('-')[0]+'_'+countryWithType.split('-')[1]) != null 
                               ? submissionCountryMap.get(countryWithType.split('-')[0]+'_'+countryWithType.split('-')[1]).Id
                               : ''; 
                               
                                Decimal calendarDays = submissionCountryMap.get(countryWithType.split('-')[0]+'_'+countryWithType.split('-')[1]) != null 
                               ? submissionCountryMap.get(countryWithType.split('-')[0]+'_'+countryWithType.split('-')[1]).Calendar_Days__c
                               : 0;
                               submissionDetails.add(new SubmissionDetail(true, countryName, submissionType, submissionTypeId, calendarDays,
                                                                          prodTicket.Product_Name__c, prodTicket.Product_List_Number__c, prodTicket.Batch_Lot_Serial__c, prodTicket.Likely_Cause__c,
                                                                          prodTicket.Id, prodTicket.GTIN_Static__c, prodTicket.Product__r.Registered_Site__c,'', prodTicket.Product__r.IVDR_Registered_Site__c
                                                                         ));
                           }                                                                                                                  
                       }                                
                   }            
               }
               isConfirmWindow = true; 
           }
        
    }
    
    /**
* @Method       : createSubmissions
* @Invoke       : From ADDS4RegulatorySubmissions Page
* @Description  : Handles the creation  of submissions
* @Return       : N/A
* @Params       : N/A
**/     
    public void createSubmissions(){
       
        registeredSiteError = false;
        registeredSiteProductError.clear();
        List<sobject> newSubmissions = new List<sobject>();
        try{
            for(SubmissionDetail SubmissionDet : SubmissionDetails){
                //Varsha Hariharan 19 Aug 2021 BugFix#15, #44
                if(SubmissionDet.isSelected){
                    if(SubmissionDet.productType == 'IVDD/MDD' && String.isBlank(SubmissionDet.productRegisteredSiteId)){
                        registeredSiteError = true;
                        registeredSiteProductError.add(SubmissionDet.productName);
                    }
                    if(SubmissionDet.productType == 'IVDR/MDR' && String.isBlank(SubmissionDet.prodTypeVar)){
                        registeredSiteError = true;
                        registeredSiteProductError.add(SubmissionDet.productName);
                    }
                    
                    if(String.isNotBlank(SubmissionDet.submissionType) && SubmissionDet.submissionType.contains('MDR')){
                        newSubmissions.add(
                            new CMPL123CME__EMDR__c(
                                CMPL123CME__Complaint__c = ticketId, 
                                Medical_Evaluation__c = assessmentId,
                                Product__c = SubmissionDet.productTicketId,
                                //CHaRM-R4: EMDR HL7 Changes replacing "CMPL123CME__Unique_Identifier_UDI__c" discontinued field with new field "CMPL123CME__D4_Primary_UDI_Number__c".
                                CMPL123CME__D4_Primary_UDI_Number__c = SubmissionDet.productTicketGTIN,
                                CMPL123CME__Registered_Site__c  = SubmissionDet.productRegisteredSiteId,
                                Submission_Type__c = SubmissionDet.submissionTypeId,
                                CMPL123CME__MDR_Due_Date__c = initialAwarenessDate != null && SubmissionDet.calendarDays != null 
                                ? initialAwarenessDate + Integer.valueOf(SubmissionDet.calendarDays) : null,
                                D9_Country1__c = countryIdMap.get(SubmissionDet.countryName) != null ? countryIdMap.get(SubmissionDet.countryName) : null
                            )
                        );
                    }
                    else if(String.isNotBlank(SubmissionDet.submissionType) && SubmissionDet.submissionType.contains('MDI')){
                        newSubmissions.add(
                            new CMPL123CME__MEDDEV__c(
                                CMPL123CME__Complaint__c = ticketId, 
                                Medical_Evaluation__c = assessmentId,
                                Product__c = SubmissionDet.productTicketId, 
                                Submission_Type__c = SubmissionDet.submissionTypeId,
                                //CHaRM-R5: Updated the mapping of the Registered site for the MDI submissions and to get the registerd site value from MDI/MIR Registered Sitefield from Product for IPDR 652
                                Registered_Site__c = SubmissionDet.prodTypeVar,
                                Submission_Due_Date__c = initialAwarenessDate != null && SubmissionDet.calendarDays != null 
                                ? initialAwarenessDate + Integer.valueOf(SubmissionDet.calendarDays) : null,
                                Country__c = countryIdMap.get(SubmissionDet.countryName) != null ? countryIdMap.get(SubmissionDet.countryName) : null,
                                CMPL123CME__Type_of_Report__c = 'Initial report',
                                CMPL123CME__Manufacturer_Preliminary_Analysis__c = currentQuestionnaire.Initial_Follow_Up_Mfg_Analysis_New__c,
                                CMPL123CME__Classification_of_Incident__c = isDeath != false ? 'Death' : null
                            )
                        );
                    }
                    /*CHaRM R8: EUMIR submission are created for submission type 'EUMIR' or 'GB MIR'*/
                    else if(String.isNotBlank(SubmissionDet.submissionType) && (SubmissionDet.submissionType.contains('EUMIR') || SubmissionDet.submissionType.contains('GB MIR'))) {
                        newSubmissions.add(
                            new CMPL123CME__EU_MIR__c(
                                CMPL123CME__Complaint__c = ticketId, 
                                MedicalEvaluation__c = assessmentId,
                                Product_Type__c = SubmissionDet.productType,
                                Product__c = SubmissionDet.productTicketId, 
                                Submission_Type__c = SubmissionDet.submissionTypeId,
                                //Varsha Hariharan 19 Aug 2021 BugFix#15, #44
                                //CHaRM-R5: Updated the mapping of the Registered site for the MIR submissions and to get the registerd site value from MDI/MIR Registered Sitefield from Product for IPDR 652
                                Registered_Site__c = SubmissionDet.productType == 'IVDD/MDD'? SubmissionDet.prodTypeVar : SubmissionDet.productType == 'IVDR/MDR'? SubmissionDet.prodTypeVar : '',
                                Date_Due__c = initialAwarenessDate != null && SubmissionDet.calendarDays != null 
                                ? initialAwarenessDate + Integer.valueOf(SubmissionDet.calendarDays) : null,
                                Country__c = countryIdMap.get(SubmissionDet.countryName) != null ? countryIdMap.get(SubmissionDet.countryName) : null,
                                //@Juneid 20 - Sep-2021, Updated Report Type 'Initial Report' to 'Initial'
                                CMPL123CME__Type_of_Report__c = 'Initial',
                                CMPL123CME__Preliminary_Results_And_Conclusions__c = currentQuestionnaire.Initial_Follow_Up_Mfg_Analysis_New__c,
                                CMPL123CME__Classification_of_Incident__c = isDeath != false ? 'Death' : null                     
                            )
                            
                        );
                          
                    }
                }
            }
            if(registeredSiteError){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'As selected product(s) '+JSON.serialize(registeredSiteProductError)+' does not contain registered site, submission cannot be created.');
                    ApexPages.addMessage(myMsg);
            }else{
                if(newSubmissions.size() > 0){
                    // Added - W-000157 - chunks error fix on sobject - start
                    newSubmissions.sort();
                    // Added - W-000157 - chunks error fix on sobject - start
                    if(Schema.sObjectType.CMPL123CME__EMDR__c.isCreateable() && Schema.sObjectType.CMPL123CME__MEDDEV__c.isCreateable() && Schema.sObjectType.CMPL123CME__EU_MIR__c.isCreateable() ){
                        insert newSubmissions;
                        update new CMPL123CME__Questionnaire__c(Id = assessmentId, Submission_Created__c = true);
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,Label.Medical_Evaluation_Submission_Record)); 
                    }else{
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'User does not have access to create submissions.');
                        ApexPages.addMessage(myMsg);
                    }
                    
                }
                
            }
        }catch(Exception exp){
            ApexPages.addMessages(exp);    
        } 
        
    }
    /**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : SubmissionDetail
* @Why   : DTO class to define the class members
* @When  : 23-MAR-2017
* @Where : From ADDS4RegulatorySubmissions Page
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Admin                23-MAR-2017            Work ID / Case ID     Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/    
    public class SubmissionDetail{
        public Boolean isSelected{get;set;}
        public String countryName{get;set;}
        public String submissionType{get;set;}
        public String submissionTypeId{get;set;}
        public Decimal calendarDays{get;set;}
        public String productName{get;set;}
        public String productListNo{get;set;}
        public String batchLot{get;set;}
        public String likelyCause{get;set;}
        public String productTicketId{get;set;}
        public String productTicketGTIN{get;set;}
        public String productRegisteredSiteId{get;set;}
        //@Juneid 7 June 2021, IVDD/IVDR code selection
        public String productType{get;set;}
        //Varsha Hariharan 19 Aug 2021 BugFix#15, #44
        public String prodTypeVar{get;set;}
        
        //Varsha Hariharan 19 Aug 2021 BugFix#15, #44
        public SubmissionDetail(Boolean isSelected, String countryName, String submissionType, String submissionTypeId, 
                                Decimal calendarDays, String productName, String productListNo, String batchLot, String likelyCause, String productTicketId, String productTicketGTIN, String productRegisteredSiteId, String productType, String IVDRPdtRegdSite){
                                    
                                    this.isSelected = isSelected;
                                    this.countryName = countryName;
                                    this.submissionType = submissionType;
                                    this.submissionTypeId = submissionTypeId;
                                    this.calendarDays = calendarDays;
                                    this.productName = productName;
                                    this.productListNo = productListNo;
                                    this.batchLot = batchLot;
                                    this.likelyCause = likelyCause;
                                    this.productTicketId = productTicketId;  
                                    this.productTicketGTIN = productTicketGTIN;
                                    this.productRegisteredSiteId = productRegisteredSiteId;
                                    //@Juneid 7 June 2021, IVDD/IVDR code selection
                                    this.productType  = productType;
                                    //Varsha Hariharan 19 Aug 2021 BugFix#15, #44
                                    this.prodTypeVar = IVDRPdtRegdSite;
                                }
    }

    
}