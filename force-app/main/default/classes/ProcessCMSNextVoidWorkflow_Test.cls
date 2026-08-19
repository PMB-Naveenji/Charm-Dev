/* 
* @why  : ProcessCMSNextVoidWorkflow_Test class for the ProcessCMSNextVoidWorkflow
* @when : CreatedDate : 15-OCT-2018         ModifiedDate : 
* @what : Class to Handle Different scenarios from Ticket Trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 05-JAN-2021           Upgrade Issue #41           Adjusted test setup data.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ProcessCMSNextVoidWorkflow_Test {
 
    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
     @testSetup static void setup(){
        
        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(
                new ADD_App_Settings__c(
                        Restrict_Process_Builders__c = true
                ), true);
        
          //Create Country
        Country__c country = (Country__c)TestDataFactory.createSObject(new Country__c(
            Name = 'INDIA',Primary_Vigilance_Contact__c = UserInfo.getUserId() ),true);
        
        // Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'Yes',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            Overall_Reportable_Status__c = 'Not Reportable',
            CMSNext__c = 'Void',
            Complaint_Demotion_rationale__c = ''
        ), true);
        
        //Create Workflow Status 
        CMPL123__WF_Status__c  status = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Opened'),true);
        
        //Create Workflow Status 
        CMPL123__WF_Status__c  statusClosed = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Closed-Voided'),true);
        
        //Create Workflow Action 
        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Void'),true);
        
        //Create Workflow rule
        CMPL123__WF_Rule__c  rule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'CMPL123CME__Investigation__c(PRODEVAL_WORKFLOW)',
            CMPL123__Record_Type__c  = 'PRODEVAL_WORKFLOW',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);
        
        //Create workflow step
        CMPL123__WF_Step__c step = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = status.Id,
            CMPL123__End_Status__c  = statusClosed.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__WF_Rule__c = rule.Id),true);
        
          //Create Workflow rule for customer response
        CMPL123__WF_Rule__c  responseRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'Customer_Response__c(Complaint_Customer_Response)',
            CMPL123__Record_Type__c  = 'Complaint_Customer_Response',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);
        
        //Create workflow step for customer response
        CMPL123__WF_Step__c responseStep = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = status.Id,
            CMPL123__End_Status__c  = statusClosed.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__WF_Rule__c = responseRule.Id),true);
        
        //Create Workflow rule for medical evaulation
        CMPL123__WF_Rule__c  questionRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Target_Object__c = 'CMPL123CME__Questionnaire__c',
            CMPL123__Record_Type__c  = 'closevoid',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);
        
        //Create workflow step for medical evaulation
        CMPL123__WF_Step__c questionStep = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = status.Id,
            CMPL123__End_Status__c  = statusClosed.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__Is_Start_Step__c = true,
            CMPL123__WF_Rule__c = questionRule.Id),true);
        
        //Create Customer Response 
        Customer_Response__c customerRes = (Customer_Response__c) TestDataFactory.createSObject(new Customer_Response__c(
            CMPL123_WF_Status__c = 'Opened',
            Event__c = complaint.Id),true);
        
        //Create Medical Evaluation
        CMPL123CME__Questionnaire__c medEval = (CMPL123CME__Questionnaire__c)TestDataFactory.createSObject (new CMPL123CME__Questionnaire__c(
            CMPL123_WF_Status__c = 'Opened',
            CMPL123CME__Complaint__c = complaint.Id),true);
        
    }
    
    
    /*
    * @Method       : invocableTest
    * @Description  : Creating the required test data for Complaint code.  
    * @Return       : N/A
    * @Params       : N/A
    */ 
    static testmethod void invocableTest(){
        
        Test.startTest();
        
       // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,Name,CMPL123CME__CMPL123_WF_Status__c,Complaint_Demotion_rationale__c ,
                                              (SELECT Id,Investigation_Evaluation__r.CMPL123_WF_Status__c 
                                               FROM Ticket_Product_Evaluation_Investigation__r),
                                              (SELECT Id,Name,CMPL123_WF_Status__c,Event__c FROM Customer_responses__r),
                                              (SELECT Id,Name,CMPL123_WF_Status__c FROM CMPL123CME__Questionnaires__r 
                                               WHERE CMPL123_WF_Status__c = 'Opened')
                                              FROM CMPL123CME__Complaint__c WHERE Overall_Reportable_Status__c = 'Not Reportable' LIMIT 1];
        
        //Assert for Prod Eval
        System.assert([SELECT Id, Name FROM CMPL123CME__Investigation__c 
                       WHERE CMPL123CME__Complaint__c =: complaint.Id].size() == 1);
        
        //Get Investigation 
        CMPL123CME__Investigation__c inv = [SELECT Id,CMPL123_WF_Status__c, Name FROM CMPL123CME__Investigation__c 
                                            WHERE CMPL123CME__Complaint__c =: complaint.Id LIMIT 1];
        
        // Update Investigation
        inv.CMPL123_WF_Status__c = 'Assess';
        TestDataFactory.updateSObject(inv);
        
        complaint = [SELECT Id,Name,CMPL123CME__CMPL123_WF_Status__c,Complaint_Demotion_rationale__c ,CMSNext__c,
                     (SELECT Id,Investigation_Evaluation__r.CMPL123_WF_Status__c 
                      FROM Ticket_Product_Evaluation_Investigation__r)
                     FROM CMPL123CME__Complaint__c WHERE Overall_Reportable_Status__c = 'Not Reportable' LIMIT 1];
 
         // Update Complaint
        complaint.CMSNext__c = 'Select One';
        TestDataFactory.updateSObject(complaint);
       
         complaint = [SELECT Id,Name,CMPL123CME__CMPL123_WF_Status__c,Complaint_Demotion_rationale__c ,CMSNext__c,
                     (SELECT Id,Investigation_Evaluation__r.CMPL123_WF_Status__c 
                      FROM Ticket_Product_Evaluation_Investigation__r)
                     FROM CMPL123CME__Complaint__c WHERE Overall_Reportable_Status__c = 'Not Reportable' LIMIT 1];
        Test.stopTest();
        //Assert for voiding the Product Eval child record
        System.assertEquals('Assess', complaint.Ticket_Product_Evaluation_Investigation__r[0].Investigation_Evaluation__r.CMPL123_WF_Status__c);
      
    }
    
    /*
    * @Method       : ProcessVoidWorkflowTest.
    * @Description  : To test the ProcessVoidWorkflow functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void ProcessVoidWorkflowTest() {
        List<CMPL123CME__Questionnaire__c> questionnaires = [SELECT Id, Voided_Rationale__c FROM CMPL123CME__Questionnaire__c];
        for(CMPL123CME__Questionnaire__c  medEval : questionnaires) {
            medEval.Voided_Rationale__c = 'Voided';
            TestDataFactory.updateSObject(medEval);
        }
        List<CMPL123CME__Complaint__c> complaints = [SELECT Id FROM CMPL123CME__Complaint__c];
		
        Test.startTest();
        ProcessCMSNextVoidWorkflow.ProcessVoidWorkflow(complaints);
        Test.stopTest();
        
        for(CMPL123CME__Questionnaire__c  medEval : [SELECT Id, CMPL123_WF_Status__c FROM CMPL123CME__Questionnaire__c]) {
            System.assertEquals('Closed-Voided', medEval.CMPL123_WF_Status__c, 'Medical Evaluation records should be in Closed-Voided WorkFlow Status');
        } 
    }
    
}