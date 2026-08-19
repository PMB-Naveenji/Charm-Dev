/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketCustomReportController.
* @Why   : Apex class to fetch the ticket with it's child and grand child records, to display on the page.
* @When  : 23-MAR-2017.
* @Where : From TicketCustomReportController.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                    Modification ID              Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017             Work ID / Case ID            Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020             Code Audit                   Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020             Code Audit                   Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020             Code Audit                   Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Charm COE	               02-JUN-2026             CHaRM R9.0/IPDR-155,         Updated SOQL query to fetches MDCs record using Ticket Record Id 
*												   IPDR-254 & IPDR-841			instead of Registration_Ticket__c field, ensuring all MDCs 
*																				across the ticket lifecycle are retrieved.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class TicketCustomReportController{
    public List<CMPL123CME__Complaint__c> ticketWithChildsAndGrandChildsList{get;set;}
    public List<Ticket_Product_Evaluation_Investigation__c> prodEvalsList{get;set;}
    public List<Medical_Evaluation_Task__c> medEvalTaskList{get;set;}
    public List<Task_Product_Evaluation_Investigation__c> tasksList{get;set;}
    public List<CMPL123__MDC_Ticket__c> unAckMDCList{get;set;}
    // Added for 1139
    public String ticketType{get;private set;}
    
    /*
    * @Method       : TicketCustomReportController.
    * @Description  : Constructor.
    * @Invoke       : Events from TriggerHandler before insert.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController controller.
    */
    public TicketCustomReportController(ApexPages.StandardController controller) {
        String ticketId = ApexPages.CurrentPage().getparameters().get('id');
        
        //Query ticket with childs and grand childs
        ticketWithChildsAndGrandChildsList = [SELECT Id, Registration_Ticket_Number__c, CMPL123CME__CMPL123_WF_Status__c, 
            Registration_Ticket_Status__c, Ticket_Last_Updated_By__c, Registration_Ticket__c, CMSNext_Ticket_Number__c,
            LastModifiedBy.Name, Ticket_Type__c,
            
            (SELECT Id, Name, CMPL123_WF_Status__c, Evaluator__r.Name FROM CMPL123CME__Questionnaires__r
                WHERE CMPL123_WF_Status__c != 'Closed-Voided' AND CMPL123_WF_Status__c != 'Closed-Done'),
            
            (SELECT Id, Name, CMPL123_WF_Status__c, Assignee_Name__r.Name FROM Returns__r 
                WHERE CMPL123_WF_Status__c != 'Closed-Voided' AND CMPL123_WF_Status__c != 'Closed-Done'),
                
            (SELECT Id, Name, Assignee_Name__r.Name, CMPL123_WF_Status__c FROM Translation_Tasks__r 
                WHERE CMPL123_WF_Status__c != 'Closed-Voided' AND CMPL123_WF_Status__c != 'Closed-Done'),
                
            (SELECT Id, Name, Assign_To__r.Name, CMPL123_WF_Status__c FROM Customer_Responses__r 
                WHERE CMPL123_WF_Status__c != 'Closed-Voided' AND CMPL123_WF_Status__c != 'Closed-Done'),
                
            (SELECT Name, Id, CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__EMDR__r 
                WHERE CMPL123CME__CMPL123_WF_Status__c != 'Closed-Voided' AND CMPL123CME__CMPL123_WF_Status__c != 'Closed-Done'),
                
            (SELECT Id, Name, CMPL123_WF_Status__c, Regulatory_Evaluator__r.Name FROM CMPL123CME__MEDDEV__r
                WHERE CMPL123_WF_Status__c != 'Closed-Voided' AND CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed - Waived'),
                
            //@Lakshman
            (SELECT Id, Name, CMPL123_WF_Status__c, Medical_Evaluator__r.Name FROM CMPL123CME__EU_MIR__r
                WHERE CMPL123_WF_Status__c != 'Closed-Voided' AND CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed - Waived'),
                 
             (SELECT  Name, Request_Status__c, Request_Type__c,Question_Action__c  FROM Meaningful_Data_Requests__r
                WHERE Request_Status__c != 'Completed' AND Request_Status__c != 'Voided')
             
             FROM CMPL123CME__Complaint__c WHERE Id =: ticketId];
             
            
            for(CMPL123CME__Complaint__c Complaint : ticketWithChildsAndGrandChildsList){
                ticketType = Complaint.Ticket_Type__c;
                break;
            }
        
        
        prodEvalsList = [SELECT Id,Investigation_Evaluation__r.CMPL123_WF_Status__c, Investigation_Evaluation__r.Name, 
                        Investigation_Evaluation__r.Assessor__r.Name, Investigation_Evaluation__r.Evaluator_Investigator__r.Name,
                        Investigation_Evaluation__r.Approver__r.Name, Type__c, Ticket__c
                        FROM Ticket_Product_Evaluation_Investigation__c 
                        WHERE Ticket__c =: ticketId 
                        AND Investigation_Evaluation__r.CMPL123_WF_Status__c != 'Closed-Done' 
                        AND Investigation_Evaluation__r.CMPL123_WF_Status__c != 'Closed-Voided'];
                        
        tasksList = [SELECT Id, Investigation_Evaluation__c, Task__c, Task__r.RecordType.Name, Task__r.CMPL123_WF_Status__c,
                    Investigation_Evaluation__r.Name, 
                    Task__r.Assignee_Name__r.Name, Source_Leveraged__c, Investigation_Evaluation__r.CMPL123CME__Complaint__c
                    FROM Task_Product_Evaluation_Investigation__c WHERE Investigation_Evaluation__r.CMPL123CME__Complaint__c =: ticketId
                    AND Task__r.CMPL123_WF_Status__c != 'Closed-Done' AND Task__r.CMPL123_WF_Status__c != 'Closed-Voided'];
                    
        medEvalTaskList =  [SELECT Id, RecordType.Name, Assignee_Name__r.Name, CMPL123_WF_Status__c, Name 
                            FROM Medical_Evaluation_Task__c
                            WHERE Medical_Evaluation__r.CMPL123CME__Complaint__c =: ticketId
                            AND CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided'];
                            
        if(ticketWithChildsAndGrandChildsList.size() >0){
            // CHaRM R9.0/IPDR-155, IPDR-254 & IPDR-841 - updated where condition replaced CMPL123__Related_Record_Detail__c =: regTicketNumber with Related_Ticket_Id__c. 
            unAckMDCList = [SELECT CMPL123__Field_Name__c, CMPL123__MDC_Trigger_Name__c , Selected_Group_Name__c
                            FROM CMPL123__MDC_Ticket__c  
                            WHERE Related_Ticket_Id__c =: ticketWithChildsAndGrandChildsList[0].Id		
                            AND CMPL123__All_Acks_Received__c = false];
        }
    }
}