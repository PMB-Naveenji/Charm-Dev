/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3_InvestigationCustomRLController.
* @Why   : Handles all the customization involved on ADDS3_InvestigationCustomRelatedlist page.
* @When  : 23-MAR-2017.
* @Where : From ADDS3_InvestigationCustomRelatedlist page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                  Modification ID            Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				  23-MAR-2017			Work ID / Case ID          Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   04-06-2020            Code Audit                 Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                   15-06-2020            Code Audit                 Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                   12-AUG-2020           Code Audit                 Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                   08-SEP-2020           Code Audit                 Added escapeSingleQuotes to ADDS3_InvestigationCustomRLController 
*                                                                          method query.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDS3_InvestigationCustomRLController{

    public List<Ticket_Product_Evaluation_Investigation__c> investigationChildren {set;get;}
    Public String keyPrefix{set;get;}
    Public String invKeyPrefix{set;get;}
    Public String complaintRecordId{set;get;}
    Public String complaintName{set;get;}
    private ApexPages.StandardController standardController;
    Public Boolean displayButtons{set;get;}
    public String disconnectedId{set;get;}

    /*
    * @Method       : Constructor.
    * @Description  : To get the Id from page and checks the respective complaint Workflow Status.
    * @Invoke       : From ADDS3_InvestigationCustomRelatedlist page.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController standardController.
    */
    public ADDS3_InvestigationCustomRLController(ApexPages.StandardController standardController){

        this.standardController = standardController;
        complaintRecordId = ApexPages.currentPage().getParameters().get('id');
        investigationChildren = new List<Ticket_Product_Evaluation_Investigation__c>();
        invKeyPrefix = CMPL123CME__Investigation__c.sObjectType.getDescribe().getKeyPrefix();
        displayButtons = false;
        if(!Test.isRunningTest()){
            this.standardController.addFields(new List<String>{'Name', 'CMPL123CME__CMPL123_WF_Status__c'});
        }
        CMPL123CME__Complaint__c currentComplaint = (CMPL123CME__Complaint__c)standardController.getRecord();

        complaintName = currentComplaint.Name;
        if(currentComplaint.CMPL123CME__CMPL123_WF_Status__c == 'Opened'){
            displayButtons = true;
        }

        if(complaintRecordId != null){
            keyPrefix = complaintRecordId.substring(0,3);
            String queryString = 'SELECT Id, Ticket__c, Investigation_Evaluation__c, Name, Type__c';
            String returnList = ApexPages.currentPage().getParameters().get('q');

            Set<String> defaultFields = new Set<String>{'Id', 'Ticket__c', 'Investigation_Evaluation__c', 'Name', 'Type__c'};

            for(Schema.FieldSetMember f : SObjectType.Ticket_Product_Evaluation_Investigation__c.FieldSets.ADDS3_Custom_Related_List_Columns.getFields()){
                if(!defaultFields.contains(f.getFieldPath())){
                    queryString += ',' + f.getFieldPath() ;
                }
            }

            queryString = queryString + ' FROM Ticket_Product_Evaluation_Investigation__c WHERE Ticket__c =: complaintRecordId';
            if(returnList != null){
                queryString = queryString + ' ORDER BY DESC';
            }else{
                queryString = queryString + ' ORDER BY CreatedDate DESC LIMIT 10';
            }
            investigationChildren = Database.query(String.escapeSingleQuotes(queryString));
        }
    }

    /*
    * @Method       : disconnectInvestigations.
    * @Description  : To disconnect investigations.
    * @Invoke       : From ADDS3_InvestigationCustomRelatedlist page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void disconnectInvestigations(){
        if(disconnectedId != null && disconnectedId != ''){
            List<Id> investigationIdSet = disconnectedId.split(';');
            delete [SELECT Id FROM Ticket_Product_Evaluation_Investigation__c Where Id IN: investigationIdSet];
        }
    }


}