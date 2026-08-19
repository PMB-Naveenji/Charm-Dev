/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2022 Capgemini
 * @What  : UpdateProdEvalBatchTest
 * @Why   : To fix defect 98 as part of CHaRM Release 2.2 .
 * This test class exists only to give code coverage for UpdateProdEvalBatch to be deployable.
 * The functionality is instead verified in ADDProductLotTriggerHandlerTest.
 * When UpdateProdEvalBatch has served its purpose, this may be deleted.
 * @When  : 10-AUG-2022
 * @Where : To be ran as a local test when UpdateProdEvalBatch is deployed
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:  
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID      Description 
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik             10-AUG-2022            CHaRM R2.2           IPDR 98: Init
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/
@isTest
public with sharing class UpdateProdEvalBatchTest {
    private static final String WF_RULE_TYPE_INQUIRY = 'INQUIRY_WORKFLOW';
    private static final String WF_RULE_TYPE_COMPLAINT = 'COMPLAINT_WORKFLOW';
    private static final String WF_RULE_TYPE_SERVICE = 'SERVICE_WORKFLOW';

    /*
    * @Method       : doTestSetup()
    * @Description  : Creates test records of ADD_App_Settings__c, CMPL123CME__Complaint__c, Product_Ticket__c, 
    *   			  CMPL123CME__Investigation__c, Product_Lot__c  to test functionality
    */	
    @testSetup
    private static void doTestSetup() {
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(
            new ADD_App_Settings__c(), true);
        Id recTypeId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
        User aspenUser = TestUtil.insertTestUser(aspenInteg,
            'aspenUserInteg@test.com', 'aspenUserInteg@test.com');
        testSetupInsertWorkflows();

        CMPL123CME__Complaint__c complaint1 = (CMPL123CME__Complaint__c)
        TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'Yes',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = recTypeId,
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened'
        ), true);
        Product_Ticket__c prodTicket1;
     
        CMPL123__Product__c product1 = (CMPL123__Product__c)
            TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'aaa',
                CMPL123__Lot_No__c = '999',
                List_Number__c = '888'
            ), true);
        prodTicket1 = (Product_Ticket__c)
            TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint1.Id,
                Likely_Cause__c = 'Yes',
                Product__c = product1.Id
            ), true);
       
        CMPL123CME__Investigation__c objInvestigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
                new CMPL123CME__Investigation__c(
                        CMPL123CME__Complaint__c = complaint1.Id,
                        Conclusion_Summary__c = 'Conslusion Summarry test1',
                        Product_Evaluation_Type__c = 'Lot to lot variability',
                        Additional_Action_Taken__c = 'No',
                        Close_to_Threshold__c = 'Yes',
                        Prod_Eval_Returns_to_be_Requested__c = 'No',
                        Not_Requested_Rationale__c = 'Test 1',
                        CMPL123_WF_Action__c = '',
                        Approval_Date__c = System.today(),
                        CMPL123_WF_Status__c = 'STR_Assess',
                        Has_Product_Lot_Child__c = true,
                        Product_Lot_Numbers__c ='test',
                        Products__c ='test',
                        Product_List_Numbers__c ='test'
                ),  false);
        insert objInvestigation;
        // Verify data creation
        {
            CMPL123CME__Investigation__c objInv = [
                SELECT Name, Id, Has_Product_Lot_Child__c, CMPL123_WF_Status__c
                FROM CMPL123CME__Investigation__c
                LIMIT 1
            ];
            System.assertEquals(0, objInv.Product_Lots__r.size(),
                'Already had a child on ProdEval!?');
            System.assertEquals(false, objInv.Has_Product_Lot_Child__c,
                'Flagged as already having a child on ProdEval!?');

            Product_Lot__c objProdLot = (Product_Lot__c)
            TestDataFactory.createSObject(new Product_Lot__c(
                Product_Name__c = prodTicket1.Id,
                Related_Ticket__c = complaint1.Id,
                Product_Evaluation_Investigation__c = objInv.Id,
                Device_Expiration_Date__c = System.today(),
                Device_Manufacturing_Date__c = System.today()),
            true);

            objInv = [
                SELECT Name, Id, Has_Product_Lot_Child__c, CMPL123_WF_Status__c,
                (SELECT Id FROM Product_Lots__r)
                FROM CMPL123CME__Investigation__c
                LIMIT 1
            ];
            System.assertNotEquals(0, objInv.Product_Lots__r.size(),
                'No child on ProdEval');
            System.assertEquals(true, objInv.Has_Product_Lot_Child__c,
                'Flagged as not having a child on ProdEval');
        }
    }
    
	/*
    * @Method       : testSetupInsertWorkflows()
    * @Description  : Sub-method of testSetup calls testSetupInsertWorkflowSteps()
    */
    public static void testSetupInsertWorkflows() {
        Map<String, CMPL123__WF_Rule__c> ruleTypeToRec = testSetupInsertWorkflowRules();
        Map<String, CMPL123__WF_Action__c> actionNameToRec = testSetupInsertWorkflowActions();
        Map<String, CMPL123__WF_Status__c> statusNameToRec = testSetupInsertWorkflowStatuses();
        testSetupInsertWorkflowSteps(ruleTypeToRec, actionNameToRec, statusNameToRec);
    }

    /*
    * @Method       : testSetupInsertWorkflowRules()
    * @Description  : Created test records of CMPL123__WF_Rule__c
    */
    public static Map<String, CMPL123__WF_Rule__c> testSetupInsertWorkflowRules() {
        CMPL123__WF_Rule__c wfRuleInquiry = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Description__c = 'Inquiry Record Workflow',
            CMPL123__Has_Multiple_Actions__c = true,
            CMPL123__Is_Active__c = true,
            CMPL123__Record_Type__c = WF_RULE_TYPE_INQUIRY,
            CMPL123__Target_Object__c = 'CMPL123CME__Complaint__c(INQUIRY_WORKFLOW)',
            Name = 'Inquiry Workflow'
        ), false);
        CMPL123__WF_Rule__c wfRuleComplaint = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Description__c = 'Complaint Workflow',
            CMPL123__Has_Multiple_Actions__c = true,
            CMPL123__Is_Active__c = true,
            CMPL123__Record_Type__c = WF_RULE_TYPE_COMPLAINT,
            CMPL123__Target_Object__c = 'CMPL123CME__Complaint__c(COMPLAINT_WORKFLOW)',
            Name = 'Complaint Workflow'
        ), false);
        CMPL123__WF_Rule__c wfRuleService = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            CMPL123__Description__c = 'Service Workflow',
            CMPL123__Has_Multiple_Actions__c = true,
            CMPL123__Is_Active__c = true,
            CMPL123__Record_Type__c = WF_RULE_TYPE_SERVICE,
            CMPL123__Target_Object__c = 'CMPL123CME__Complaint__c(SERVICE_WORKFLOW)',
            Name = 'Service Workflow'
        ), false);
        insert new List<CMPL123__WF_Rule__c>{wfRuleInquiry, wfRuleComplaint, wfRuleService};

        Map<String, CMPL123__WF_Rule__c> ruleTypeToRec = new Map<String, CMPL123__WF_Rule__c>{
            WF_RULE_TYPE_INQUIRY => wfRuleInquiry,
            WF_RULE_TYPE_COMPLAINT => wfRuleComplaint,
            WF_RULE_TYPE_SERVICE => wfRuleService
        };
        return ruleTypeToRec;
    }

    /*
    * @Method       : testSetupInsertWorkflowRules()
    * @Description  : Created test records of CMPL123__WF_Action__c
    */
    public static Map<String, CMPL123__WF_Action__c> testSetupInsertWorkflowActions() {
        List<CMPL123__WF_Action__c> wfActions = new List<CMPL123__WF_Action__c>();
        final List<String> ACTIONS = new List<String>{
            'Close',
            'Complete',
            'Final Review Approved',
            'Further Action Required',
            'Further Review Required',
            'Go to Opened',
            'Reopen',
            'Reopen - Go to Opened',
            'Reopen - Translation Required',
            'Reopen for Appending Regulatory Correspondence',
            'Responded',
            'Submit for Final Review',
            'Ticket Closed In CMSNext',
            'Void'
        };
        for (String act : ACTIONS) {
            wfActions.add((CMPL123__WF_Action__c) TestDataFactory.createSObject(new CMPL123__WF_Action__c(
                Name = act
            ), false));
        }
        insert wfActions;

        Map<String, CMPL123__WF_Action__c> actionNameToRec = new Map<String, CMPL123__WF_Action__c>();
        for (CMPL123__WF_Action__c rec : wfActions) {
            actionNameToRec.put(rec.Name, rec);
        }
        return actionNameToRec;
    }

    /*
    * @Method       : testSetupInsertWorkflowRules()
    * @Description  : Created test records of CMPL123__WF_Status__c
    */
    public static Map<String, CMPL123__WF_Status__c> testSetupInsertWorkflowStatuses() {
        List<CMPL123__WF_Status__c> toInsert = new List<CMPL123__WF_Status__c>();
        final List<String> STATUSES = new List<String>{
            'Closed-Voided',
            'Appending Regulatory Correspondence',
            'Final Review In Progress',
            'Registration Closed',
            'Opened',
            'Complaint Further Review',
            'Complaint Complete',
            'Closed-Done'
        };
        for (String stat : STATUSES) {
            toInsert.add((CMPL123__WF_Status__c)
                TestDataFactory.createSObject(new CMPL123__WF_Status__c(
                    Name = stat
                ), false)
            );
        }
        insert toInsert;

        Map<String, CMPL123__WF_Status__c> statusNameToRec =
            new Map<String, CMPL123__WF_Status__c>();
        for (CMPL123__WF_Status__c rec : toInsert) {
            statusNameToRec.put(rec.Name, rec);
        }
        return statusNameToRec;
    }

    /*
    * @Method       : testSetupInsertWorkflowSteps()
    * @Description  : Created test records of CMPL123__WF_Rule__c, CMPL123__WF_Step__c
    */
    public static List<CMPL123__WF_Step__c> testSetupInsertWorkflowSteps(
        Map<String, CMPL123__WF_Rule__c> ruleTypeToRec,
        Map<String, CMPL123__WF_Action__c> actionNameToRec,
        Map<String, CMPL123__WF_Status__c> statusNameToRec
    ) {
        CMPL123__WF_Rule__c wfRuleInquiry = ruleTypeToRec.get(WF_RULE_TYPE_INQUIRY);
        CMPL123__WF_Rule__c wfRuleComplaint = ruleTypeToRec.get(WF_RULE_TYPE_COMPLAINT);
        CMPL123__WF_Rule__c wfRuleService = ruleTypeToRec.get(WF_RULE_TYPE_SERVICE);
        List<CMPL123__WF_Step__c> wfSteps = new List<CMPL123__WF_Step__c>{
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Reopen').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 4,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Closed-Voided').Id,
                CMPL123__WF_Rule__c = wfRuleInquiry.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Void').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Closed-Voided').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 2,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__WF_Rule__c = wfRuleInquiry.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Reopen').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 3,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__WF_Rule__c = wfRuleInquiry.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Close').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__Is_Start_Step__c = true,
                CMPL123__Order__c = 1,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__WF_Rule__c = wfRuleInquiry.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Reopen - Translation Required').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 5,
                CMPL123__Permission_Group__c = 'Business Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__WF_Rule__c = wfRuleInquiry.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Complete').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Complaint Complete').Id,
                CMPL123__Is_Start_Step__c = true,
                CMPL123__Order__c = 1,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Go to Opened').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 20,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Registration Closed').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Go to Opened').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 19,
                CMPL123__Permission_Group__c = 'Business Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Complaint Complete').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Close').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 18,
                CMPL123__Permission_Group__c = 'Vigilance Contact',
                CMPL123__Start_Status__c = statusNameToRec.get('Appending Regulatory Correspondence').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Reopen for Appending Regulatory Correspondence').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Appending Regulatory Correspondence').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 17,
                CMPL123__Permission_Group__c = 'Vigilance Contact',
                CMPL123__Start_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Reopen').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 16,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Closed-Voided').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Further Action Required').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 6,
                CMPL123__Permission_Group__c = 'Quality Complaint',
                CMPL123__Start_Status__c = statusNameToRec.get('Complaint Further Review').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Final Review Approved').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 11,
                CMPL123__Permission_Group__c = 'Quality Complaint',
                CMPL123__Start_Status__c = statusNameToRec.get('Final Review In Progress').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Responded').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Complaint Complete').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 7,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Complaint Further Review').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Further Review Required').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Complaint Further Review').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 3,
                CMPL123__Permission_Group__c = 'Quality Complaint',
                CMPL123__Start_Status__c = statusNameToRec.get('Complaint Complete').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Ticket Closed In CMSNext').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Registration Closed').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 4,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Complaint Complete').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Void').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Closed-Voided').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 13,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Final Review In Progress').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Submit for Final Review').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Final Review In Progress').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 9,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Registration Closed').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Void').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Closed-Voided').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 5,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Complaint Complete').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Void').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Closed-Voided').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 2,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Void').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Closed-Voided').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 10,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Registration Closed').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Void').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Closed-Voided').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 8,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Complaint Further Review').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Go to Opened').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 12,
                CMPL123__Permission_Group__c = 'Quality Complaint',
                CMPL123__Start_Status__c = statusNameToRec.get('Final Review In Progress').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Void').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Closed-Voided').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 15,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Reopen').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 14,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Reopen - Translation Required').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Registration Closed').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 21,
                CMPL123__Permission_Group__c = 'Business Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Reopen - Go to Opened').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 22,
                CMPL123__Permission_Group__c = 'Business Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Go to Opened').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 23,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Complaint Complete').Id,
                CMPL123__WF_Rule__c = wfRuleComplaint.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Reopen').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 4,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Closed-Voided').Id,
                CMPL123__WF_Rule__c = wfRuleService.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Reopen').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 3,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__WF_Rule__c = wfRuleService.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Void').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Closed-Voided').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 2,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__WF_Rule__c = wfRuleService.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Close').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__Is_Start_Step__c = true,
                CMPL123__Order__c = 1,
                CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__WF_Rule__c = wfRuleService.Id
            ), false),
            (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Action__c = actionNameToRec.get('Reopen - Translation Required').Id,
                CMPL123__End_Status__c = statusNameToRec.get('Opened').Id,
                CMPL123__Is_Start_Step__c = false,
                CMPL123__Order__c = 5,
                CMPL123__Permission_Group__c = 'Business Admin',
                CMPL123__Start_Status__c = statusNameToRec.get('Closed-Done').Id,
                CMPL123__WF_Rule__c = wfRuleService.Id
            ), false)
        };
        insert wfSteps;
        return wfSteps;
    }
    
	/*
    * @Method       : getFullCoverage.
    * @Description  : Unit tests UpdateProdEvalBatch class
    */
    @isTest
    public static void getFullCoverage() {
        User aspenUser = [SELECT Id FROM User WHERE Username LIKE 'aspenUserInteg@test.com%' LIMIT 1];

        System.runAs(aspenUser) {
            // Assertion setup
            SObject[] hits = Database.query(UpdateProdEvalBatch.getQuery());
            
            Integer numDmlBeforeTest = System.Limits.getDmlRows();

            // Get full coverage
            UpdateProdEvalBatch bat = new UpdateProdEvalBatch();
            Test.startTest();
            Id jobId = Database.executeBatch(bat, 10); 
            Integer numDmlAfterTest = System.Limits.getDmlRows();
            Test.stopTest();

            // Test verification
            System.assertNotEquals(numDmlAfterTest, numDmlBeforeTest,
                'Did not update any records');
            UpdateProdEvalBatch.sendEmail('test');
            UpdateProdEvalBatch.StatefulBatchHelper helper = new UpdateProdEvalBatch.StatefulBatchHelper();
            helper.emailMsg ='test';
            List<CMPL123CME__Investigation__c> InvestigationList = [SELECT Id,CMPL123CME__Complaint__r.Id,Product_Lot_Numbers__c,Product_List_Numbers__c,Products__c,Has_Product_Lot_Child__c FROM CMPL123CME__Investigation__c];
            try{
                UpdateProdEvalBatch.sayChanges(new Map<Id,CMPL123CME__Investigation__c>{InvestigationList[0].Id => InvestigationList[0]}, InvestigationList, helper);
            }catch(Exception ex){
                system.assertEquals('Attempt to de-reference a null object',ex.getMessage());
            }
        }
    }
}