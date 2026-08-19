/** 
 * @why  : ADDInvestigationHandlerTest class for the ADDInvestigationHandler, CMPL123CME_Investigation_AuditTrigger
 * @when : CreatedDate : 24-AUG-2018         ModifiedDate : 18-APR-2019
 * @what : Class to Handle Different scenarios from Investigation Trigger.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:  
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID      	 Description 
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   oivan                    02-MAR-2020            CHARM-1879 (CR 1600-B)       Modified
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   rslob                    03-June-2020           N/A                          Test class optimization
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   DSkak                    04-06-2020             Code Audit                   Removed 'System.debug()'.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   rsitc                    10-June-2020           N/A                          Updated code part, which is related to Users' insertion. 
                                                                                  This change designed to prevent a 'DUPLICATE_USERNAME'
                                                                                  error during deployment to Production environment
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    15-06-2020             Code Audit                   Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   rsitc                    20-MAY-2020            Fix Def #102                 Adjusted setup() and testPEReviewProdEval(), 
 *                                                                                added testPEReviewProdEvalNegative().
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   rsitc                    11-JAN-2020            Upgrade WF Rules migration   Added updateKILogLookupTest, wfActionFieldsUpdateTest
 *                                                                                autosetRegistrationNumberTest, wfActionFieldsUpdateTest2
 *                                                                                test methods for covering logic from moved WF Rules.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Yadram                    10-FEB-2022            CHaRM R2.1                   To fix defect #261, we have commented out code, so we
 *                                                                                had to invert the assertion of the corresponding tester
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Larry Resnik              28-NOV-2022            CHaRM R2.2.1                 Add tests for defect 66. Optimized testSetup by merging
 *                                                                                DML and SOQL, and by avoiding @future.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Larry Resnik              08-JUN-2023            CHaRM R3.1                   Add tests for defect 299 -- mainly for updateMedEvals.
 * Re-introduced @future for testSetup due to crashes by Too Many Soql Queries. More magic words replaced with constants.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/

@isTest
class ADDInvestigationHandlerTest {
    // Populates Product-Ticket's Batch/Lot/Serial#
    private static final String PT_BATCH_LOT_NUM1 = '1234';
    private static final String PT_BATCH_LOT_NUM2 = 'Lot678';
    // Populates Product's List Number. Referenced by Product-Ticket's Product_List_Number__c
    private static final String PRODUCT_LIST_NUM1 = '12345';
    private static final String PRODUCT_LIST_NUM2 = '01L86-01';
    private static final String PRODUCT_LIST_NUM3 = 'FOR-MEDEVALS';
    // Populates Product's Name. Referenced by Product-Ticket's Product_Name__c
    private static final String PRODUCT_NAME1 = 'PATH Vysion';
    private static final String PRODUCT_NAME2 = 'ARC I1000SR MOD';
    private static final String PRODUCT_NAME3 = 'JUST FOR MEDEVALS';
    // External Id for CMSNext Ticket Number. Use these to pinpoint Tickets made in testSetup
    private static final String CMSNEXT_NUM_ONE = '123456';
    private static final String CMSNEXT_NUM_80064_WITH_MEDEVAL = '987654';
    private static final String CMSNEXT_NUM_80067_WITH_MEDEVAL = '111222';
    private static final String CMSNEXT_NUM_80064_NO_MEDEVAL = '555444';
    private static final String CMSNEXT_NUM_80067_NO_MEDEVAL = '333222';
    private static final String CMSNEXT_NUM_80064_VOID_MEDEVAL = '922554';
    private static final String CMSNEXT_NUM_80067_VOID_MEDEVAL = '519873';
    // Emails used to pinpoint Users
    private static final String EMAIL_UNRESTRICTED = 'unrestricted';
    // Error messages and substrings
    private static final String ERROR_POS = TestUtil.ERROR_POS;
    private static final String ERROR_NEG = TestUtil.ERROR_NEG;
    private static final String ERROR_SETUP = TestUtil.ERROR_SETUP;

    /**
     * @Method       : afterInsertTest
     * @Description  : Creating the required test data for Product Evluation/Investigation custom code.
     * @Return       : N/A
     * @Params       : N/A
     * @Revision     : 28-NOV-2022 Larry: Merged Profile and User DML and SOQL
     * to work alongside governor limits. Removed the unnecessary @future test setup sub function.
     **/
    @TestSetup
    static void setup() {
        Map<String, Profile> profileNameToRecord = new Map<String, Profile>();
        for (Profile prof : [SELECT Id, Name FROM Profile
            WHERE Name IN :new List<String>{'Aspen User', 'System Administrator', 'ASPEN Integration'}
        ]) {
            profileNameToRecord.put(prof.Name, prof);
        }
        Profile aspenUserProfile = profileNameToRecord.get('Aspen User');
        Profile sysAdminProfile = profileNameToRecord.get('System Administrator');
        Profile integProfile = profileNameToRecord.get('ASPEN Integration');
        User aspenUser = TestUtil.makeTestUser(
            integProfile.Id,
            'aspenUserTest@test.com',
            'aspenUserTest@test.com.test',
            false
        );

        User userAssessor = TestUtil.makeTestUser(
            aspenUserProfile.Id,
            'raj@test.com',
            'hiii12@test.com',
            'PEA2',
            false
        );

        User userInvestigator = TestUtil.makeTestUser(
            aspenUserProfile.Id,
            'raj@test.com',
            'hiii@test.com',
            'PEI3',
            false
        );

        User userApprover = TestUtil.makeTestUser(
            aspenUserProfile.Id,
            'raj@test.com',
            'hiii23@test.com',
            'PEA4',
            false
        );

        User qcaUser = TestUtil.makeTestUser(
            aspenUserProfile.Id,
            'raj@test.com',
            'qca@test.com',
            'PEA4',
            false
        );

        User ceiUser = TestUtil.makeTestUser(
            aspenUserProfile.Id,
            'raj@test.com',
            'cei@test.com',
            'PEA4',
            false
        );

        User adminUser = TestUtil.makeTestUser(
            sysAdminProfile.Id,
            'raj@test.com',
            'adminuserfortest@test.com',
            'PEA4',
            false
        );

        User userUnrestricted = TestUtil.makeTestUser(
            sysAdminProfile.Id,
            EMAIL_UNRESTRICTED + '@test.com',
            EMAIL_UNRESTRICTED + '@test.com',
            false
        );
        insert new SObject[]{
            aspenUser, userAssessor, userInvestigator,
            userApprover, qcaUser, ceiUser, adminUser, userUnrestricted
        };

        // Create Complaint
        String complaintRTId = SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c = 'ADD',
            pRE_Status__c = 'Yes',
            Country_of_origin__c = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c = 'IA-CC',
            Ticket_Type__c = 'Complaint',
            Is_Product_Evaluation_Investigation_chil__c = false,
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            CMSNext_Ticket_Number__c = CMSNEXT_NUM_ONE
        ), false);
        CMPL123CME__Complaint__c ticket80064allMedEvals = complaint.clone();
        ticket80064allMedEvals.CMSNext_Ticket_Number__c = CMSNEXT_NUM_80064_WITH_MEDEVAL;
        CMPL123CME__Complaint__c ticket80067allMedEvals = complaint.clone();
        ticket80067allMedEvals.CMSNext_Ticket_Number__c = CMSNEXT_NUM_80067_WITH_MEDEVAL;
        CMPL123CME__Complaint__c ticket80064noMedEvals = complaint.clone();
        ticket80064noMedEvals.CMSNext_Ticket_Number__c = CMSNEXT_NUM_80064_NO_MEDEVAL;
        CMPL123CME__Complaint__c ticket80067noMedEvals = complaint.clone();
        ticket80067noMedEvals.CMSNext_Ticket_Number__c = CMSNEXT_NUM_80067_NO_MEDEVAL;
        CMPL123CME__Complaint__c ticket80064voidMedEvals = complaint.clone();
        ticket80064voidMedEvals.CMSNext_Ticket_Number__c = CMSNEXT_NUM_80064_VOID_MEDEVAL;
        CMPL123CME__Complaint__c ticket80067voidMedEvals = complaint.clone();
        ticket80067voidMedEvals.CMSNext_Ticket_Number__c = CMSNEXT_NUM_80067_VOID_MEDEVAL;
        insert new CMPL123CME__Complaint__c[]{ complaint, ticket80064allMedEvals, ticket80067allMedEvals };
        insert new CMPL123CME__Complaint__c[]{ ticket80064noMedEvals, ticket80067noMedEvals };
        insert new CMPL123CME__Complaint__c[]{ ticket80064voidMedEvals, ticket80067voidMedEvals };

        setupInsertWorkFlows();

        System.runAs(aspenUser) {
            // Create Product
            CMPL123__Product__c product1 = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                    // Set an external Id just to allow inserts to be combined
                    External_ID__c = '1',
                    Name = PRODUCT_NAME1,
                    CMPL123__Lot_No__c = '123',
                    List_Number__c = PRODUCT_LIST_NUM1),
                false
            );
            CMPL123__Product__c product2 = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                    External_ID__c = '2',
                    Name = PRODUCT_NAME2,
                    CMPL123__Lot_No__c = '456',
                    List_Number__c = PRODUCT_LIST_NUM2),
                false
            );
            CMPL123__Product__c product3 = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                    External_ID__c = '3',
                    Name = PRODUCT_NAME3,
                    CMPL123__Lot_No__c = '789',
                    List_Number__c = PRODUCT_LIST_NUM3),
                false
            );
            CMPL123__Product__c product4 = (CMPL123__Product__c) TestDataFactory.createSObject(
                new CMPL123__Product__c(
                    External_ID__c = '4',
                    Name = PRODUCT_NAME3,
                    CMPL123__Lot_No__c = '777',
                    List_Number__c = PRODUCT_LIST_NUM3),
                false
            );
            Product_Ticket__c productTicket1 = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = PT_BATCH_LOT_NUM1,
                    Likely_Cause__c = AspenConstants.STR_Yes,
                    Delete_Flag__c = false,
                    Product__r = new CMPL123__Product__c(External_ID__c = '1')),
                false
            );
            Product_Ticket__c productTicket2 = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(
                    Event_Ticket__c = complaint.Id,
                    Batch_Lot_Serial__c = PT_BATCH_LOT_NUM2,
                    Likely_Cause__c = AspenConstants.STR_Yes,
                    Delete_Flag__c = false,
                    Product__r = new CMPL123__Product__c(External_ID__c = '2')),
                false
            );
            Product_Ticket__c productTicket3 = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(
                    Event_Ticket__c = ticket80064allMedEvals.Id,
                    Batch_Lot_Serial__c = PT_BATCH_LOT_NUM2,
                    Likely_Cause__c = AspenConstants.STR_Yes,
                    Delete_Flag__c = false,
                    Product__r = new CMPL123__Product__c(External_ID__c = '3')),
                false
            );
            Product_Ticket__c productTicket4 = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(
                    Event_Ticket__c = ticket80064voidMedEvals.Id,
                    Batch_Lot_Serial__c = PT_BATCH_LOT_NUM2,
                    Likely_Cause__c = AspenConstants.STR_Yes,
                    Delete_Flag__c = false,
                    Product__r = new CMPL123__Product__c(External_ID__c = '4')),
                false
            );
            insert new SObject[] {product1, product2, product3, product4,
                productTicket1, productTicket2, productTicket3, productTicket4};

            CMPL123CME__Investigation__c objInvestigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
                new CMPL123CME__Investigation__c(
                    CMPL123CME__Complaint__c = complaint.Id,
                    Assessor__c = userAssessor.Id,
                    Evaluator_Investigator__c = userInvestigator.Id,
                    Conclusion_Summary__c = 'Conslusion Summarry test1',
                    //objInvestigation.Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction;
                    Product_Evaluation_Type__c = 'Lot to lot variability',
                    Approver__c = userApprover.Id,
                    Additional_Action_Taken__c = 'No',
                    Close_to_Threshold__c = 'Yes',
                    Prod_Eval_Returns_to_be_Requested__c = 'No',
                    Not_Requested_Rationale__c = 'Test 1',
                    CMPL123_WF_Action__c = '',
                    CMPL123_WF_Status__c = AspenConstants.STR_Assess,
                    Approval_Date__c = System.today()
                ),  false);
            CMPL123CME__Investigation__c objInvestigation2 = objInvestigation.clone();
            objInvestigation2.Conclusion_Summary__c = 'Conslusion Summarry test2';
            objInvestigation2.Not_Requested_Rationale__c = 'Test 2';
            CMPL123CME__Investigation__c prodEval3 = objInvestigation.clone();
            prodEval3.CMPL123CME__Complaint__c = ticket80064allMedEvals.Id;
            prodEval3.Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction;
            CMPL123CME__Investigation__c prodEval4 = objInvestigation.clone();
            prodEval4.CMPL123CME__Complaint__c = ticket80067allMedEvals.Id;
            prodEval4.Conclusion_Disposition__c = AspenConstants.STR_80067_Deficiency_Malfunction;
            CMPL123CME__Investigation__c prodEval5 = objInvestigation.clone();
            prodEval5.CMPL123CME__Complaint__c = ticket80064noMedEvals.Id;
            prodEval5.Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction;
            CMPL123CME__Investigation__c prodEval6 = objInvestigation.clone();
            prodEval6.CMPL123CME__Complaint__c = ticket80067noMedEvals.Id;
            prodEval6.Conclusion_Disposition__c = AspenConstants.STR_80067_Deficiency_Malfunction;
            CMPL123CME__Investigation__c prodEval7 = objInvestigation.clone();
            prodEval7.CMPL123CME__Complaint__c = ticket80064voidMedEvals.Id;
            prodEval7.Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction;
            CMPL123CME__Investigation__c prodEval8 = objInvestigation.clone();
            prodEval8.CMPL123CME__Complaint__c = ticket80067voidMedEvals.Id;
            prodEval8.Conclusion_Disposition__c = AspenConstants.STR_80067_Deficiency_Malfunction;
            insert new List<CMPL123CME__Investigation__c>{
                objInvestigation, objInvestigation2, prodEval3, prodEval4,
                prodEval5, prodEval6, prodEval7, prodEval8
            };
        }
        
        insertData();
    }

    /**
     * Inserts WorkFlow-related records for testSetup
     * @author Larry Resnik
     * @date 31-MAY-2023
     */
    private static void setupInsertWorkFlows() {
        CMPL123__WF_Rule__c wfRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
            new CMPL123__WF_Rule__c(
                Name = 'Medical Evaluation Workflow',
                CMPL123__Is_Active__c = true,
                CMPL123__Has_Multiple_Actions__c = true,
                CMPL123__Record_Type__c = AspenConstants.STR_MEDICAL_EVALUATION_WORKFLOW,
                CMPL123__Target_Object__c = 'CMPL123CME__Questionnaire__c(MEDICAL_EVALUATION_WORKFLOW)'
        ), false);

        Map<String, CMPL123__WF_Status__c> statusNameToRec = new Map<String, CMPL123__WF_Status__c>{
            AspenConstants.STR_WF_Opened => (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = AspenConstants.STR_WF_Opened), false),
            AspenConstants.STR_Regulatory => (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = AspenConstants.STR_Regulatory), false),
            AspenConstants.STR_WF_Closed_Done => (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = AspenConstants.STR_WF_Closed_Done), false),
            AspenConstants.STR_In_Process_Evaluation => (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = AspenConstants.STR_In_Process_Evaluation), false),
            AspenConstants.STR_WF_Closed_Voided => (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = AspenConstants.STR_WF_Closed_Voided), false)
        };
        insert statusNameToRec.values();

        CMPL123__WF_Action__c wfActionVoid = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
            new CMPL123__WF_Action__c(
                Name = AspenConstants.STR_WF_Action_Void,
                CMPL123__Is_ESign_Required__c = false
        ), false);
        CMPL123__WF_Action__c wfActionReopen = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
            new CMPL123__WF_Action__c(
                Name = AspenConstants.STR_Reopen,
                CMPL123__Is_ESign_Required__c = false
        ), false);
        CMPL123__WF_Action__c wfActionGoToEval = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
            new CMPL123__WF_Action__c(
                Name = AspenConstants.WF_ACTION_TO_PROC_EVAL,
                CMPL123__Is_ESign_Required__c = false
        ), false);
        insert new SObject[]{ wfRule, wfActionReopen, wfActionGoToEval, wfActionVoid };

        insert new SObject[]{
            TestDataFactory.createSObject(
                new CMPL123__WF_Step__c(
                    CMPL123__Action__c = wfActionVoid.Id,
                    CMPL123__End_Status__c = statusNameToRec.get(AspenConstants.STR_WF_Closed_Voided).Id,
                    CMPL123__Is_Start_Step__c = true,
                    CMPL123__Order__c = 1.0,
                    CMPL123__Permission_Group__c = '$Evaluator__c',
                    CMPL123__Start_Status__c = statusNameToRec.get(AspenConstants.STR_WF_Opened).Id,
                    CMPL123__WF_Rule__c = wfRule.Id
            ), false),
            TestDataFactory.createSObject(
                new CMPL123__WF_Step__c(
                    CMPL123__Action__c = wfActionGoToEval.Id,
                    CMPL123__End_Status__c = statusNameToRec.get(AspenConstants.STR_In_Process_Evaluation).Id,
                    CMPL123__Is_Start_Step__c = false,
                    CMPL123__Order__c = 5.0,
                    CMPL123__Permission_Group__c = '$Evaluator__c',
                    CMPL123__Start_Status__c = statusNameToRec.get(AspenConstants.STR_Regulatory).Id,
                    CMPL123__WF_Rule__c = wfRule.Id
            ), false),
            TestDataFactory.createSObject(
                new CMPL123__WF_Step__c(
                    CMPL123__Action__c = wfActionReopen.Id,
                    CMPL123__End_Status__c = statusNameToRec.get(AspenConstants.STR_In_Process_Evaluation).Id,
                    CMPL123__Is_Start_Step__c = false,
                    CMPL123__Order__c = 8.0,
                    CMPL123__Permission_Group__c = 'System Admin',
                    CMPL123__Start_Status__c = statusNameToRec.get(AspenConstants.STR_WF_Closed_Done).Id,
                    CMPL123__WF_Rule__c = wfRule.Id
            ), false)
        };
    }
    
    @future
    public static void insertData () {
        User usr = [SELECT Id FROM User WHERE Username LIKE 'aspenUserTest@test.com%' LIMIT 1];
        Map<String, CMPL123CME__Complaint__c> cmsNextNumToTicket = new Map<String, CMPL123CME__Complaint__c>();
        for (CMPL123CME__Complaint__c ticket : [
            SELECT Id, CMSNext_Ticket_Number__c,
            (SELECT Id, CMPL123_WF_Status__c FROM CMPL123CME__Investigations__r),
            (
                SELECT Id, CMPL123_WF_Status__c, Reportability_Rationale__c,
                Reportability__c, Reportability_Category__c, Voided_Rationale__c
                FROM CMPL123CME__Questionnaires__r
            ),
            (SELECT Id, Batch_Lot_Serial__c, Likely_Cause__c FROM Products_Events__r)
            FROM CMPL123CME__Complaint__c
        ]) {
            cmsNextNumToTicket.put(ticket.CMSNext_Ticket_Number__c, ticket);
        }

        System.runAs(usr) {
            setupAdjustMedEvals(cmsNextNumToTicket, usr);

            // Dereference some records for easy access
            CMPL123CME__Complaint__c complaint = cmsNextNumToTicket.get(CMSNEXT_NUM_ONE);
            CMPL123CME__Complaint__c ticketTwo = cmsNextNumToTicket.get(CMSNEXT_NUM_80064_WITH_MEDEVAL);
            CMPL123CME__Complaint__c ticketThree = cmsNextNumToTicket.get(CMSNEXT_NUM_80067_WITH_MEDEVAL);
            CMPL123CME__Investigation__c objInvestigation = complaint.CMPL123CME__Investigations__r[0];
            CMPL123CME__Investigation__c objInvestigation2 = complaint.CMPL123CME__Investigations__r[1];

            Product_Ticket__c productTicket1;
            for (Product_Ticket__c ptJunc : complaint.Products_Events__r) {
                if (ptJunc.Batch_Lot_Serial__c == PT_BATCH_LOT_NUM1) {
                    productTicket1 = ptJunc;
                    break;
                }
            }
            Assert.isNotNull(productTicket1, 'Setup bug: Did not find the Product-Ticket made in testSetup');

            String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Ticket History Review By Product List Number').getRecordTypeId();
            // String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Threshold Review').getRecordTypeId();
            Task__c objTask = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = objInvestigation.Id,
                RecordTypeId = taskRTId,
                CMPL123_WF_Status__c = 'Closed-Done',
                Threshold_Review_Conclusion__c = 'Complaint does not exceed the threshold',
                Conclusion__c = 'Just because',
                Result__c = 'test'), false);
            Task__c objTask2 = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = objInvestigation2.Id,
                RecordTypeId = taskRTId,
                CMPL123_WF_Status__c = 'Opened',
                Threshold_Review_Conclusion__c = 'Threshold exceeded',
                Result__c = 'test'), false);
            insert new List<Task__c>{objTask, objTask2};

            insert new SObject[]{
                TestDataFactory.createSObject(new Task_Product_Evaluation_Investigation__c(
                    Investigation_Evaluation__c = objInvestigation.Id, 
                    Task__c = objTask.Id, 
                    Source_Leveraged__c = 'Source'
                ), false),
                TestDataFactory.createSObject(new Task_Product_Evaluation_Investigation__c(
                    Investigation_Evaluation__c = objInvestigation2.Id, 
                    Task__c = objTask2.Id, 
                    Source_Leveraged__c = 'Source'
                ), false),
                TestDataFactory.createSObject(new Product_Lot__c(
                    Product_Evaluation_Investigation__c = objInvestigation.Id,
                    Related_Ticket__c = complaint.Id,
                    Product_Name__c = productTicket1.Id
                ), false),
                TestDataFactory.createSObject(new Product_Lot__c(
                    Product_Evaluation_Investigation__c = objInvestigation2.Id,
                    Related_Ticket__c = complaint.Id,
                    Product_Name__c = productTicket1.Id
                ), false)
            };
        }
    }

    private static void setupAdjustMedEvals(
        Map<String, CMPL123CME__Complaint__c> cmsNextNumToTicket,
        User medEvalUser
    ) {
        CMPL123CME__Complaint__c ticketTwo = cmsNextNumToTicket.get(CMSNEXT_NUM_80064_WITH_MEDEVAL);
        CMPL123CME__Complaint__c ticketThree = cmsNextNumToTicket.get(CMSNEXT_NUM_80067_WITH_MEDEVAL);
        CMPL123CME__Complaint__c ticketFour = cmsNextNumToTicket.get(CMSNEXT_NUM_80064_VOID_MEDEVAL);
        CMPL123CME__Complaint__c ticketFive = cmsNextNumToTicket.get(CMSNEXT_NUM_80067_VOID_MEDEVAL);

        // Fix the existing MedEvals to have a WorkFlow Status instead of null
        {
            CMPL123CME__Questionnaire__c medEvalForTwo = ticketTwo.CMPL123CME__Questionnaires__r[0];
            medEvalForTwo.CMPL123_WF_Status__c = AspenConstants.STR_Opened;
            medEvalForTwo.Evaluator__c = medEvalUser.Id;
            CMPL123CME__Questionnaire__c medEvalForThree = ticketThree.CMPL123CME__Questionnaires__r[0];
            medEvalForThree.CMPL123_WF_Status__c = AspenConstants.STR_Opened;
            medEvalForThree.Evaluator__c = medEvalUser.Id;
            // CMPL123CME__Questionnaire__c medEvalForFour = ticketFour.CMPL123CME__Questionnaires__r[0];
            // medEvalForFour.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Voided;
            // medEvalForFour.Evaluator__c = medEvalUser.Id;
            // CMPL123CME__Questionnaire__c medEvalForFive = ticketFive.CMPL123CME__Questionnaires__r[0];
            // medEvalForFive.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Voided;
            // medEvalForFive.Evaluator__c = medEvalUser.Id;
            update new List<SObject>{ medEvalForTwo, medEvalForThree/*, medEvalForFour, medEvalForFive*/ };
        }

        // Create MedEvals for all potential WorkFlow Status it can be in.
        // ("Opened" is handled by the code right before this)
        final List<String> MEDEVAL_STATUSES = new List<String>{
            AspenConstants.STR_In_Process_Evaluation,
            AspenConstants.STR_WF_Closed_Done,
            AspenConstants.STR_WF_Closed_Voided,
            AspenConstants.STR_Regulatory
        };
        List<CMPL123CME__Complaint__c> relevantTickets = new List<CMPL123CME__Complaint__c>{
            ticketTwo, ticketThree
        };
        List<CMPL123CME__Questionnaire__c> medEvalList = new List<CMPL123CME__Questionnaire__c>();
        for (CMPL123CME__Complaint__c ticket : relevantTickets) {
            for (String stat : MEDEVAL_STATUSES) {
                medEvalList.add((CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                    CMPL123CME__Complaint__c = ticket.Id,
                    CMPL123_WF_Status__c = stat,
                    // All fields below this comment are required at some WorkFlow Status, but
                    // do not affect how the MedEval gets processed
                    Evaluator__c = medEvalUser.Id,
                    Initial_Awareness_Date__c = System.today(),
                    Reportability_Rationale__c = 'Just because',
                    Reportability_Category__c = 'Adverse Event',
                    Reportability__c = 'Non-Reportable',
                    Targeted_Assessment_No_of_Days__c = 5,
                    Voided_Rationale__c = 'For no reason'
                ), false));
            }
        }

        // Make voided MedEvals for specific tickets
        CMPL123CME__Questionnaire__c voidedMedEvalOne = medEvalList.get(medEvalList.size() - 1).clone();
        voidedMedEvalOne.CMPL123CME__Complaint__c = ticketFour.Id;
        voidedMedEvalOne.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Voided;
        CMPL123CME__Questionnaire__c voidedMedEvalTwo = voidedMedEvalOne.clone();
        voidedMedEvalTwo.CMPL123CME__Complaint__c = ticketFive.Id;
        medEvalList.add(voidedMedEvalOne);
        medEvalList.add(voidedMedEvalTwo);

        insert medEvalList;
    }

    /**
    * @Method       : testSubmitforEvaluationProdEval
    * @Description  : update the Product Evluation/Investigation fields
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testSubmitForEvaluationProdEval() {
        Test.startTest();
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, Name,CMSNext_Ticket_Number__c FROM CMPL123CME__Complaint__c LIMIT 1];
        // Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c, Assessor__c, Assessor__r.Name 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];

        objInvestigation.CMPL123_WF_Action__c = 'Submit for Evaluation';
        objInvestigation.CMPL123_WF_Status__c = 'In Process-Evaluation';
        update objInvestigation;

        Test.stopTest();
        //Check System Generated Prod Eval Workflow Action
        System.assertEquals('Submit for Evaluation', [SELECT Id, CMPL123_WF_Action__c FROM CMPL123CME__Investigation__c WHERE Id = :objInvestigation.Id].CMPL123_WF_Action__c);

    }

    /**
    * @Method       : testConcludeProdEval
    * @Description  : update the Product Evluation/Investigation fields
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testConcludeProdEval() {
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, Name,CMSNext_Ticket_Number__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        // Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];
        User aspenUser = [SELECT Id FROM User WHERE Username LIKE 'aspenUserTest@test.com.test%' LIMIT 1];

        Test.startTest();
        try {
            objInvestigation.Voided_Rationale__c = 'Test';
            objInvestigation.No_Investigation_Rationale__c = 'Yes';
            objInvestigation.Prod_Eval_Returns_to_be_Requested__c = 'Yes';
            objInvestigation.Prod_eval_KI_Log__c = true;
            objInvestigation.CMPL123_WF_Action__c = 'No Investigation Required';
            objInvestigation.CMPL123_WF_Status__c = 'Conclude';
            TestDataFactory.updateSObject(objInvestigation);
        }
        Catch (Exception e) {
            String message = e.getMessage();
            System.debug('===Exception===' + e);
            System.assert(message.contains('Required field Device Manufacturing Date/Device Manufacturing Date Unknown/Device Manufacturing Date NA and Expiration Date/Device Expiration Date Unknown/Device Expiration Date NA of Product/Lot should not be empty'), 'message=' + message);
        }

        String trendItemRTId = Schema.SObjectType.Trend_Item__c.getRecordTypeInfosByName().get('Thresholds').getRecordTypeId();
        Trend_Item__c trendItem = (Trend_Item__c) TestDataFactory.createSObject(new Trend_Item__c(
                Process__c = 'Thresholds',
                RecordTypeId = trendItemRTId
        ), true);

        CMPL123__Product__c product = new CMPL123__Product__c(
                Name = PRODUCT_NAME1,
                CMPL123__Lot_No__c = '123',
                List_Number__c = PRODUCT_LIST_NUM1
            );
        System.runAs(aspenUser) {
            product = (CMPL123__Product__c) TestDataFactory.createSObject(product, true);
        }

        Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = 'Yes',
                Product__c = product.Id), true);
        Product_Lot__c prodLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
                Product_Evaluation_Investigation__c = objInvestigation.Id,
                Product_Name__c = prodTicket.Id,
                Related_Ticket__c = complaint.Id,
                Device_Expiration_Date__c = Date.newInstance(2019, 01, 12),
                Device_Expiration_Date_NA__c = false,
                Device_Expiration_Date_Unknown__c = false,
                Device_Manufacturing_Date__c = Date.newInstance(2019, 01, 01),
                Device_Manufacturing_Date_NA__c = false
                //CMPL123_WF_Status__c = 'Opened'
        ), true);

        prodLot.Device_Expiration_Date__c = System.today();
        prodLot.Device_Expiration_Date_NA__c = false;
        prodLot.Device_Expiration_Date_Unknown__c = false;
        prodLot.Device_Manufacturing_Date__c = System.today();
        prodLot.Device_Manufacturing_Date_NA__c = false;
        //TestDataFactory.updateSObject(prodLot);

        try {
            objInvestigation.Voided_Rationale__c = 'Test';
            objInvestigation.No_Investigation_Rationale__c = 'Yes';
            objInvestigation.Prod_Eval_Returns_to_be_Requested__c = 'Yes';
            objInvestigation.Prod_eval_KI_Log__c = true;
            objInvestigation.CMPL123_WF_Action__c = 'No Investigation Required';
            objInvestigation.CMPL123_WF_Status__c = 'Conclude';
            TestDataFactory.updateSObject(objInvestigation);
        }
        Catch (Exception e) {
            String message = e.getMessage();
            System.debug('===Exception===' + e);
            System.assert(message.contains('Required field Device Manufacturing Date/Device Manufacturing Date Unknown/Device Manufacturing Date NA and Expiration Date/Device Expiration Date Unknown/Device Expiration Date NA of Product/Lot should not be empty'), 'message=' + message);
        }
        Test.stopTest();
    }

    /**
    * @Method       : testClosedVoidComplaint
    * @Description  : update the Product Evluation/Investigation and complaint fields
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testClosedVoidComplaint() {
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, Name,CMSNext_Ticket_Number__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        // Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];

        Test.startTest();
        try {
            complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Voided';
            complaint.CMPL123CME__CMPL123_WF_Action__c = 'Void';
            complaint.Complaint_Demotion_rationale__c = 'Record in Closed-Voided Status';
            complaint.Ticket_Type__c = 'Service';
            TestDataFactory.updateSObject(complaint);
            objInvestigation.CMPL123_WF_Action__c = 'Submit for Evaluation';
            objInvestigation.CMPL123_WF_Status__c = 'In Process-Evaluation';
            TestDataFactory.updateSObject(objInvestigation);
        }
        Catch (Exception e) {
            System.debug('===Exception===' + e);
        }
        Test.stopTest();
    }

    /**
    * @Method       : testPEReviewProdEval
    * @Description  : update the Product Evluation/Investigation fields
    * @Return       : N/A
    * @Params       : N/A
    **/
    // Def #102/CHARM-2576: removed incorrect assert in catch block, added correct assertation
    @isTest
    static void testPEReviewProdEval() {
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, Name,CMSNext_Ticket_Number__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        // Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c, CMPL123_WF_Action__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];

        //Get User List
        List<User> userlist = [SELECT Id FROM User WHERE Profile.Name = 'Standard User' Limit 3];
        Test.startTest();

        //Create Investigation
        if (userlist.size() >= 3) {
            CMPL123CME__Investigation__c objInv = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(new CMPL123CME__Investigation__c(
                    Assessor__c = userlist[0].Id,
                    Evaluator_Investigator__c = userlist[1].Id,
                    Conclusion_Summary__c = 'Test',
                    Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction,
                    Product_Evaluation_Type__c = 'Lot to lot variability',
                    Approver__c = userlist[2].Id,
                    Additional_Action_Taken__c = 'No',
                    Close_to_Threshold__c = 'Yes',
                    Prod_Eval_Returns_to_be_Requested__c = 'No',
                    Not_Requested_Rationale__c = 'Test',
                    //CMPL123_WF_Status__c = 'Opened',
                    CMPL123CME__Complaint__c = complaint.Id
            ), true);
            
            try {
                objInv.CMPL123_WF_Action__c = 'Submit for Review';
                objInv.CMPL123_WF_Status__c = 'PE Review';
                TestDataFactory.updateSObject(objInv);
            }
            Catch (Exception E) {
                String message = e.getMessage();
                System.debug('===Error===' + message);
                //Assert for Product/Lot child record is required before posting Submit to Review workflow action
                System.assert(message.contains('A Product/Lot child record is required before posting Submit to Review workflow action'), 'message=' + message);
            }
            
        }
        
        objInvestigation.Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction;
        objInvestigation.CMPL123_WF_Action__c = 'Submit for Review';
        objInvestigation.Prod_eval_KI_Log__c = false;
        objInvestigation.CMPL123_WF_Status__c = 'PE Review';
        TestDataFactory.updateSObject(objInvestigation);
        CMPL123CME__Investigation__c updatedInvestigation = [SELECT CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE Id = :objInvestigation.Id];
        System.assert(updatedInvestigation.CMPL123_WF_Status__c == 'PE Review');
        Test.stopTest();
    }

     /**
    * @Method       : testPEReviewProdEvalNegative
    * @Description  : check error receiving upon existing active task
    * @Return       : N/A
    * @Params       : N/A
    **/
    // Def #102/CHARM-2576: added testPEReviewProdEvalNegative method to cover negative scenario of the fix implemented
    @isTest
    static void testPEReviewProdEvalNegative() {

        CMPL123CME__Complaint__c complaint = [SELECT Id, Name,CMSNext_Ticket_Number__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 2'];
        
        String errorMessage = '';

        Test.startTest();
        objInvestigation.Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction;
        objInvestigation.CMPL123_WF_Action__c = 'Submit for Review';
        objInvestigation.CMPL123_WF_Status__c = 'PE Review';
        ADDInvestigationHandler.executeOnceBeforeUpdate = false;
        try {
            TestDataFactory.updateSObject(objInvestigation);  
        } catch (Exception e) {
            errorMessage = e.getMessage();
            
        }
        // 10-FEB-2022 Yadram : The Assert Condition needs to be Inverted.
        System.assertEquals(!errorMessage.contains(System.label.Product_evaluation_Investigation_No_Task_Closed),true,
            'Should allow Submit for Review action even when not all existing tasks are closed');
        Test.stopTest();
    }

    /**
    * @Method       : testInProInvProdEval
    * @Description  : update the Product Evluation/Investigation fields
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testInProInvProdEval() {
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, Name,CMSNext_Ticket_Number__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        // Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];
        Test.startTest();
        // Craete Product
        CMPL123__Product__c objProduct = [SELECT Id FROM CMPL123__Product__c WHERE Name = :PRODUCT_NAME1];

        // Craete Product Ticket
        Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = 'Yes',
                Product__c = objProduct.Id), true);

        //Create Product Lot
        Product_Lot__c prodLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
                Product_Evaluation_Investigation__c = objInvestigation.Id,
                Product_Name__c = prodTicket.Id,
                Related_Ticket__c = complaint.Id,
                Device_Expiration_Date__c = system.today(),
                Device_Expiration_Date_Unknown__c = false,
                Device_Manufacturing_Date__c = system.today()

        ), true);

        //Update Investigation Record
        try {
            objInvestigation.Voided_Rationale__c = 'Test';
            objInvestigation.Prod_Eval_Returns_to_be_Requested__c = 'Yes';
            objInvestigation.Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction;
            //objInvestigation.Investigation_Conclusion__c = '80067 Deficiency, Malfunction';
            objInvestigation.CMPL123_WF_Action__c = 'Investigation Required';
            objInvestigation.CMPL123_WF_Status__c = 'In Process-Investigation';

            TestDataFactory.updateSObject(objInvestigation);

        }
        Catch (Exception E) {
            System.debug('===Exception===' + E);
        }
        Test.stopTest();
    }

    /**
    * @Method       : testProdEvalwithCombination
    * @Description  : update the Product Evluation/Investigation fields
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testProdEvalwithCombination() {
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, Name,CMSNext_Ticket_Number__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        // Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];
        Test.startTest();
        // Craete Product
        CMPL123__Product__c objProduct = [SELECT Id FROM CMPL123__Product__c WHERE Name = :PRODUCT_NAME1];

        // Craete Product Ticket
        Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = 'Yes',
                Product__c = objProduct.Id), true);

        //Create Product Lot
        Product_Lot__c prodLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
                Product_Evaluation_Investigation__c = objInvestigation.Id,
                Product_Name__c = prodTicket.Id,
                Related_Ticket__c = complaint.Id,
                Device_Expiration_Date__c = system.today(),
                Device_Expiration_Date_Unknown__c = false,
                Device_Manufacturing_Date__c = system.today()

        ), true);

        //Create Task
        String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Threshold Review').getRecordTypeId();
        Task__c objTask = (Task__c) TestDataFactory.createSObject(new Task__c(Related_Investigation_Evaluation__c = objInvestigation.Id,
                RecordTypeId = taskRTId, CMPL123_WF_Status__c = 'Opened',
                Threshold_Review_Conclusion__c = 'Complaint does not exceed'), true);
        //Update Investigation Record
        complaint.Investigation_Conclusion__c = null;
        TestDataFactory.updateSObject(complaint);
        try {
            objInvestigation.Voided_Rationale__c = 'Test';
            objInvestigation.Prod_Eval_Returns_to_be_Requested__c = 'Yes';
            objInvestigation.Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem';
            objInvestigation.CMPL123_WF_Action__c = 'Investigation Required';
            objInvestigation.CMPL123_WF_Status__c = 'In Process-Investigation';

            TestDataFactory.updateSObject(objInvestigation);

        }
        Catch (Exception E) {
            System.debug('===Exception===' + E);
        }
        Test.stopTest();
    }

    /**
    * @Method       : testClosedVoidProdEval
    * @Description  : update the Product Evluation/Investigation fields
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testClosedVoidProdEval() {
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, Name,CMSNext_Ticket_Number__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        // Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];

        Test.startTest();
        //Update Investigation Record without Voided Rationale.
        try {

            objInvestigation.CMPL123_WF_Action__c = 'Void';
            objInvestigation.CMPL123_WF_Status__c = 'Closed-Voided';
            TestDataFactory.updateSObject(objInvestigation);
        }
        Catch (Exception E) {
            String message = e.getMessage();
            System.debug('===Error===' + message);
            //Assert for Product/Lot child record is required before posting Submit to Review workflow action
            System.assert(message.contains('Voided Rationale is required.'), 'message=' + message);
        }

        //Update Investigation Record with Voided Rationale.
        try {
            objInvestigation.Voided_Rationale__c = 'Test';
            objInvestigation.Prod_Eval_Returns_to_be_Requested__c = 'Yes';
            objInvestigation.CMPL123_WF_Action__c = 'Void';
            objInvestigation.CMPL123_WF_Status__c = 'Closed-Voided';
            TestDataFactory.updateSObject(objInvestigation);
        }
        Catch (Exception E) {
            String message = e.getMessage();
            System.debug('===Error===' + message);
            //Assert for Product/Lot child record is required before posting Submit to Review workflow action
            System.assert(message.contains('Voided Rationale is required.'), 'message=' + message);
        }
        Test.stopTest();
    }

    /**
    * @Method       : testClosedDoneProdEval
    * @Description  : update the Product Evluation/Investigation fields
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testClosedDoneProdEval() {
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, Name,CMSNext_Ticket_Number__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        // Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];

        Test.startTest();

        //Update Investigation Record.
        objInvestigation.Conclusion_Disposition__c = '80067 Deficiency, Malfunction';
        objInvestigation.Prod_Eval_Returns_to_be_Requested__c = 'Yes';
        objInvestigation.CMPL123_WF_Action__c = 'Approve';
        objInvestigation.CMPL123_WF_Status__c = 'Closed-Done';
        objInvestigation.CMPL123_WF_Action_Performed_On__c = System.now();
        TestDataFactory.updateSObject(objInvestigation);

        System.assertEquals('80067 Deficiency, Malfunction', [SELECT Investigation_Conclusion__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1].Investigation_Conclusion__c);
        try {
            delete objInvestigation;
        }
        Catch (Exception E) {
            String message = e.getMessage();
            System.debug('===message===' + e.getMessage());
            //Assert for Product/Lot child record is required before posting Submit to Review workflow action
            System.assert(message.contains('The Product Evaluation/Investigation cannot be deleted as it is a System Generated Source Product Evaluation/Investigation'), 'message=' + message);
        }
        Test.stopTest();
    }

    /**
    * @Method       : testReopenProdEval
    * @Description  : update the Product Evluation/Investigation fields
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testReopenProdEval() {
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, Name,CMSNext_Ticket_Number__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        // Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];

        Test.startTest();
        //Update Investigation Record.
        objInvestigation.CMPL123_WF_Action__c = 'Reopen';
        objInvestigation.CMPL123_WF_Status__c = 'Assess';
        objInvestigation.CMPL123_WF_Action_Performed_On__c = System.now();
        TestDataFactory.updateSObject(objInvestigation);


        Test.stopTest();
    }

    /**
    * @Method       : testCreatingProductLotFromTicket
    * @Description  : Create Product-Lot from Ticket
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testCreatingProductLotFromTicket() {

        Test.startTest();
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        // Create Product
        CMPL123__Product__c objProduct = [SELECT Id FROM CMPL123__Product__c WHERE Name = :PRODUCT_NAME1];

        // Create Product Ticket
        Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = 'Yes',
                Product__c = objProduct.Id), true);

        ADDInvestigationHandler.createProductLot(complaint.CMSNext_Ticket_Number__c);
        ADDInvestigationHandler objInves = new ADDInvestigationHandler();
        objInves.afterDelete();
        objInves.afterUndelete();

        Test.stopTest();
    }

    /**
    * @Method       : testCreatingTaskFromInvestigation
    * @Description  : Create Task from Investigation
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testCreatingTaskFromInvestigation() {

        Test.startTest();
        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        //Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];

        //Create Task
        String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Ticket History Review By Lot Number').getRecordTypeId();
        Task__c objTask = (Task__c) TestDataFactory.createSObject(new Task__c(Related_Investigation_Evaluation__c = objInvestigation.Id, RecordTypeId = taskRTId, CMPL123_WF_Status__c = 'Opened'), true);

        //System.assertEquals(2, [SELECT count() FROM Task_Product_Evaluation_Investigation__c]);

        //Update Investigation Record.
        objInvestigation.Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction;
        objInvestigation.CMPL123_WF_Status__c = 'Closed-Done';
        objInvestigation.CMPL123_WF_Action__c = 'Approve';
        TestDataFactory.updateSObject(objInvestigation);

        Test.stopTest();

    }
    /**
    * @Method       : test80064ProdEval
    * @Description  : Update Investigation
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void test80064ProdEval() {


        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        //Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];

        Test.startTest();
        //Update Complaint
        complaint.Investigation_Conclusion__c = 'NO Deficiency, Malfunction';
        TestDataFactory.updateSObject(complaint);

        //Update Investigation Record.

        objInvestigation.Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction;
        objInvestigation.CMPL123_WF_Status__c = 'Closed-Done';
        objInvestigation.CMPL123_WF_Action__c = 'Approve';
        objInvestigation.Prod_Eval_Returns_to_be_Requested__c = 'Yes';
        objInvestigation.CMPL123_WF_Action_Performed_On__c = System.now();
        TestDataFactory.updateSObject(objInvestigation);

        Test.stopTest();
        System.assertEquals(
            AspenConstants.STR_80064_NO_Deficiency_Malfunction.toLowerCase(),
            [SELECT Investigation_Conclusion__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1].Investigation_Conclusion__c.toLowerCase());
    }

    /**
    * @Method       : test80065ProdEval
    * @Description  : Update Investigation
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void test80065ProdEval() {


        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        //Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];

        Test.startTest();
        //Update Complaint
        complaint.Investigation_Conclusion__c = 'NO Deficiency, Malfunction';
        TestDataFactory.updateSObject(complaint);

        //Update Investigation Record.
        objInvestigation.Conclusion_Disposition__c = '80065 NO Deficiency, Malfunction, Manufacturing Defect/Distribution Issue';
        objInvestigation.CMPL123_WF_Status__c = 'Closed-Done';
        objInvestigation.CMPL123_WF_Action__c = 'Approve';
        objInvestigation.Prod_Eval_Returns_to_be_Requested__c = 'Yes';
        objInvestigation.CMPL123_WF_Action_Performed_On__c = System.now();
        TestDataFactory.updateSObject(objInvestigation);

        Test.stopTest();
        System.assertEquals('80065 NO Deficiency, Malfunction, Manufacturing Defect/Distribution Issue', [SELECT Investigation_Conclusion__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1].Investigation_Conclusion__c);
    }

    /**
    * @Method       : test80066ProdEval
    * @Description  : Update Investigation
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void test80066ProdEval() {


        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        //Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];

        Test.startTest();

        //Update Investigation Record.
        objInvestigation.Conclusion_Disposition__c = '80066 NO Deficiency, NO Malfunction';
        objInvestigation.CMPL123_WF_Status__c = 'Closed-Done';
        objInvestigation.CMPL123_WF_Action__c = 'Approve';
        objInvestigation.Prod_Eval_Returns_to_be_Requested__c = 'Yes';
        objInvestigation.CMPL123_WF_Action_Performed_On__c = System.now();
        TestDataFactory.updateSObject(objInvestigation);

        Test.stopTest();
        System.assertEquals('80066 NO Deficiency, NO Malfunction', [SELECT Investigation_Conclusion__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1].Investigation_Conclusion__c);
    }

    /**
    * @Method       : test80069ProdEval
    * @Description  : Update Investigation
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void test80069ProdEval() {


        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        //Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];

        Test.startTest();
        //Update Investigation Record.
        objInvestigation.Conclusion_Disposition__c = '80069 Non-Medical Device, Product Problem';
        objInvestigation.CMPL123_WF_Status__c = 'Closed-Done';
        objInvestigation.CMPL123_WF_Action__c = 'Approve';
        objInvestigation.Prod_Eval_Returns_to_be_Requested__c = 'Yes';
        objInvestigation.CMPL123_WF_Action_Performed_On__c = System.now();
        TestDataFactory.updateSObject(objInvestigation);

        Test.stopTest();
        System.assertEquals('80069 Non-Medical Device, Product Problem', [SELECT Investigation_Conclusion__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1].Investigation_Conclusion__c);
    }

    /**
    * @Method       : test80068ProdEval
    * @Description  : Update Investigation
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void test80068ProdEval() {


        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id, CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];

        //Get Investigation
        // Def #102/CHARM-2576: added Not_Requested_Rationale__c filter criteria because of modified test setup
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c = :complaint.Id 
            AND Assessor__c != NULL AND Not_Requested_Rationale__c = 'Test 1'];

        Test.startTest();
        //Update Investigation Record.
        objInvestigation.Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem';
        objInvestigation.CMPL123_WF_Status__c = 'Closed-Done';
        objInvestigation.CMPL123_WF_Action__c = 'Approve';
        objInvestigation.Prod_Eval_Returns_to_be_Requested__c = 'Yes';
        objInvestigation.CMPL123_WF_Action_Performed_On__c = System.now();
        TestDataFactory.updateSObject(objInvestigation);

        Test.stopTest();
        System.assertEquals('80068 Non-Medical Device, No Product Problem', [SELECT Investigation_Conclusion__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1].Investigation_Conclusion__c);

    }

    //1600-B CR start
    /**
    * @Method       : testPEReviewForQualityApprover
    * @Invoke       : From CMPL123CME_Investigation_AuditTrigger Trigger
    * @Description  : users with Quality_Complaint_Approver should be able to edit only Rejection_Rationale__c field in PE Review status
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testPEReviewForQualityApprover() {
        Test.startTest();
        User user = [SELECT Id, UserName FROM User WHERE UserName LIKE 'qca@test.com%' LIMIT 1];
        User adminUser = [SELECT Id, UserName FROM User WHERE UserName LIKE 'adminuserfortest@test.com%' LIMIT 1];
        CMPL123__Product__c product = [SELECT Id FROM CMPL123__Product__c WHERE List_Number__c = :PRODUCT_LIST_NUM1];
        System.runAs(adminUser){
            insertPSA(user.UserName, 'Quality_Complaint_Approver');
        }
        CMPL123CME__Complaint__c complaint = [SELECT Id, CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c LIMIT 1];
        CMPL123CME__Investigation__c objInv = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(new CMPL123CME__Investigation__c(
                    Assessor__c = user.Id,
                    Evaluator_Investigator__c = user.Id,
                    Conclusion_Summary__c = 'Test',
                    Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction,
                    Product_Evaluation_Type__c = 'Lot to lot variability',
                    Approver__c = [SELECT Id FROM User WHERE Username LIKE 'hiii12@test.com%' LIMIT 1].Id,
                    Additional_Action_Taken__c = 'No',
                    Close_to_Threshold__c = 'Yes',
                    Prod_Eval_Returns_to_be_Requested__c = 'No',
                    Not_Requested_Rationale__c = 'Test',
                    CMPL123CME__Complaint__c = complaint.Id
            ), true);
        Product_Ticket__c productTicket = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(Event_Ticket__c = complaint.Id, Product__c = product.Id),
                true
        );
        Product_Lot__c productLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
            Product_Evaluation_Investigation__c = objInv.Id,
            Related_Ticket__c = complaint.Id,
            Product_Name__c = productTicket.Id
        ), true);
        
        objInv.CMPL123_WF_Action__c = 'Submit for Review';
        objInv.CMPL123_WF_Status__c = 'PE Review';
        
        TestDataFactory.updateSObject(objInv);
        System.assertEquals('PE Review', 
                            [SELECT CMPL123_WF_Status__c 
                            FROM CMPL123CME__Investigation__c 
                            WHERE Id =: objInv.Id].CMPL123_WF_Status__c, 
                            'Status should be changed');
        System.runAs(user){
            objInv.Rejection_Rationale__c = 'New rejection rationale text';
            ADDInvestigationHandler.executeOnceBeforeUpdate = false;
            TestDataFactory.updateSObject(objInv);
            Boolean hasError = false;
            try {
                ADDInvestigationHandler.executeOnceBeforeUpdate = false;
                objInv.Conclusion_Summary__c = 'TEST QWERTY';
                TestDataFactory.updateSObject(objInv);
            } catch (Exception e) {
                hasError = true;
                System.assert(e.getMessage().contains(System.Label.Record_locked), 'Record lock error should be shown, but it is '+ e.getMessage());
            }
            System.assertEquals(true, hasError, 'Error should be thrown for this user');
        }
        Test.stopTest();
    }
    
    /**
    * @Method       : testPEReviewForComplEvalInvest
    * @Invoke       : From CMPL123CME_Investigation_AuditTrigger Trigger
    * @Description  : users with Complaint_Evaluator_Investigator should be able to edit only Approver__c field
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void testPEReviewForComplEvalInvest() {
        Test.startTest();
        User user = [SELECT Id, UserName FROM User WHERE UserName LIKE 'cei@test.com%' LIMIT 1];
        User adminUser = [SELECT Id, UserName FROM User WHERE UserName LIKE 'adminuserfortest@test.com%' LIMIT 1];
        CMPL123__Product__c product = [SELECT Id FROM CMPL123__Product__c WHERE List_Number__c = :PRODUCT_LIST_NUM1];
        System.runAs(adminUser){
            insertPSA(user.UserName, 'Complaint_Evaluator_Investigator');
        }
        CMPL123CME__Complaint__c complaint = [SELECT Id, CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c LIMIT 1];
        CMPL123CME__Investigation__c objInv = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(new CMPL123CME__Investigation__c(
                    Assessor__c = user.Id,
                    Evaluator_Investigator__c = user.Id,
                    Conclusion_Summary__c = 'Test',
                    Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction,
                    Product_Evaluation_Type__c = 'Lot to lot variability',
                    Approver__c = [SELECT Id FROM User WHERE Username LIKE 'hiii12@test.com%' LIMIT 1].Id,
                    Additional_Action_Taken__c = 'No',
                    Close_to_Threshold__c = 'Yes',
                    Prod_Eval_Returns_to_be_Requested__c = 'No',
                    Not_Requested_Rationale__c = 'Test',
                    CMPL123CME__Complaint__c = complaint.Id
            ), true);
        Product_Ticket__c productTicket = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(Event_Ticket__c = complaint.Id, Product__c = product.Id),
                true
        );
        Product_Lot__c productLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
            Product_Evaluation_Investigation__c = objInv.Id,
            Related_Ticket__c = complaint.Id,
            Product_Name__c = productTicket.Id
        ), true);
        
        objInv.CMPL123_WF_Action__c = 'Submit for Review';
        objInv.CMPL123_WF_Status__c = 'PE Review';
        
        TestDataFactory.updateSObject(objInv);
        System.assertEquals('PE Review', 
                            [SELECT CMPL123_WF_Status__c 
                            FROM CMPL123CME__Investigation__c 
                            WHERE Id =: objInv.Id].CMPL123_WF_Status__c, 
                            'Status should be changed');
        System.runAs(user){
            objInv.Approver__c = [SELECT Id FROM User WHERE Username LIKE 'hiii23@test.com%' LIMIT 1].Id;
            ADDInvestigationHandler.executeOnceBeforeUpdate = false;
            TestDataFactory.updateSObject(objInv);
            Boolean hasError = false;
            try {
                objInv.Conclusion_Summary__c = 'TEST QWERTY';
                ADDInvestigationHandler.executeOnceBeforeUpdate = false;
                TestDataFactory.updateSObject(objInv);
            } catch (Exception e) {
                hasError = true;
                System.assert(e.getMessage().contains(System.Label.Record_locked), 'Record lock error should be shown, but it is '+ e.getMessage());
            }
            System.assertEquals(true, hasError, 'Error should be thrown for this user');
        }
        Test.stopTest();

    }
    
    /**
    * @Method       : testPEReviewForAllOtherPS
    * @Invoke       : From CMPL123CME_Investigation_AuditTrigger Trigger
    * @Description  : users without Quality_Complaint_Approver and Complaint_Evaluator_Investigator should not be able to edit any fields in PE Review status
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    @isTest
    static void testPEReviewForAllOtherPS() {
        Test.startTest();
        User user = [SELECT Id, UserName FROM User WHERE UserName LIKE 'cei@test.com%' LIMIT 1];
        User adminUser = [SELECT Id, UserName FROM User WHERE UserName LIKE 'adminuserfortest@test.com%' LIMIT 1]; 
        CMPL123CME__Complaint__c complaint = [SELECT Id, CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c LIMIT 1];
        CMPL123__Product__c product = [SELECT Id FROM CMPL123__Product__c WHERE List_Number__c = :PRODUCT_LIST_NUM1];
        CMPL123CME__Investigation__c objInv = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(new CMPL123CME__Investigation__c(
                    Assessor__c = user.Id,
                    Evaluator_Investigator__c = user.Id,
                    Conclusion_Summary__c = 'Test',
                    Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction,
                    Product_Evaluation_Type__c = 'Lot to lot variability',
                    Approver__c = [SELECT Id FROM User WHERE Username LIKE 'hiii12@test.com%' LIMIT 1].Id,
                    Additional_Action_Taken__c = 'No',
                    Close_to_Threshold__c = 'Yes',
                    Prod_Eval_Returns_to_be_Requested__c = 'No',
                    Not_Requested_Rationale__c = 'Test',
                    //CMPL123_WF_Status__c = 'Opened',
                    CMPL123CME__Complaint__c = complaint.Id
            ), true);
        Product_Ticket__c productTicket = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(Event_Ticket__c = complaint.Id, Product__c = product.Id),
                true
        );
        Product_Lot__c productLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
            Product_Evaluation_Investigation__c = objInv.Id,
            Related_Ticket__c = complaint.Id,
            Product_Name__c = productTicket.Id
        ), true);
        
        objInv.CMPL123_WF_Action__c = 'Submit for Review';
        objInv.CMPL123_WF_Status__c = 'PE Review';
        
        TestDataFactory.updateSObject(objInv);
        System.assertEquals('PE Review', 
                            [SELECT CMPL123_WF_Status__c 
                            FROM CMPL123CME__Investigation__c 
                            WHERE Id =: objInv.Id].CMPL123_WF_Status__c, 
                            'Status should be changed');
        System.runAs(adminUser){
            Boolean hasError = false;
            try {
                ADDInvestigationHandler.executeOnceBeforeUpdate = false;
                objInv.Conclusion_Summary__c = 'TEST QWERTY';
                TestDataFactory.updateSObject(objInv);
            } catch (Exception e) {
                hasError = true;
                System.assert(e.getMessage().contains(System.Label.Record_locked), 'Record lock error should be shown, but it is '+ e.getMessage());
            }
            System.assertEquals(true, hasError, 'Error should be thrown for this user');
        }
        Test.stopTest();
    }

    /**
    * @Method       : insertPSA
    * @Description  : used to add needed Permission set to needed user for testing purpose
    * @Return       : N/A
    * @Params       : N/A
    **/
    private static void insertPSA(String userName, String permSetName){
        User user = [SELECT Id, username FROM User WHERE UserName =: userName];
        PermissionSet permissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name =: permSetName];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            PermissionSetId = permissionSet.Id,
            AssigneeId = user.Id
        );
        insert psa;
    }
    //1600-B CR end

    /*
    * @Method       : updateKILogLookupTest
    * @Description  : Tests migrated WF Rules logic related to KI Log
    * @Return       : N/A
    * @Params       : N/A
    */
    @isTest
    static void updateKILogLookupTest(){
        Test.startTest();
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id FROM CMPL123CME__Investigation__c LIMIT 1];
        KI_Log__c objKILog = (KI_Log__c) TestDataFactory.createSObject(
            new KI_Log__c(
                Type__c = 'Product Evaluation',
                Division__c = 'ADD',
                Trending_Issue_Bucket__c = 'ACON' ),true
            );
        objInvestigation.KI_Log__c = objKILog.Id;
        objInvestigation.Complaint_Summary__c = 'test';
        update objInvestigation;
        CMPL123CME__Investigation__c objInvestigationUpdated = [SELECT Prod_eval_KI_Log__c 
                                                                    FROM CMPL123CME__Investigation__c 
                                                                        WHERE Id = :objInvestigation.Id];
        System.assertEquals(true, objInvestigationUpdated.Prod_eval_KI_Log__c);

        objInvestigation.KI_Log__c = null;
        update objInvestigation;
        objInvestigationUpdated = [SELECT Prod_eval_KI_Log__c 
                                                                    FROM CMPL123CME__Investigation__c 
                                                                        WHERE Id = :objInvestigation.Id];
        System.assertEquals(false, objInvestigationUpdated.Prod_eval_KI_Log__c);
        Test.stopTest();
    }

    /*
    * @Method       : wfActionFieldsUpdateTest
    * @Description  : Tests migrated WF Rules logic related to WF Action updates
    * @Return       : N/A
    * @Params       : N/A
    */
    @isTest
    static void wfActionFieldsUpdateTest(){
        Test.startTest();
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id FROM CMPL123CME__Investigation__c LIMIT 1];
        objInvestigation.CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId();
        objInvestigation.CMPL123_WF_Action__c = 'Approve';
        update objInvestigation;
        CMPL123CME__Investigation__c objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, Approved_On__c
                                                                    FROM CMPL123CME__Investigation__c 
                                                                        WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.Approved_On__c);
        
        objInvestigation.CMPL123_WF_Action__c = 'Go to Conclude';
        update objInvestigation;
        objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, Returned_to_Conclude_On__c
        FROM CMPL123CME__Investigation__c 
            WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.Returned_to_Conclude_On__c);

        objInvestigation.CMPL123_WF_Action__c = 'Investigation Completed';
        update objInvestigation;
        objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, Investigation_Completed_On__c
        FROM CMPL123CME__Investigation__c 
            WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.Investigation_Completed_On__c);

        objInvestigation.CMPL123_WF_Action__c = 'Investigation Required';
        update objInvestigation;
        objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, Investigation_Required_On__c
        FROM CMPL123CME__Investigation__c 
            WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.Investigation_Required_On__c);

        objInvestigation.CMPL123_WF_Action__c = 'No Investigation Required';
        objInvestigation.No_Investigation_Rationale__c = 'Test';
        update objInvestigation;
        objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, No_Investigation_Required_On__c
        FROM CMPL123CME__Investigation__c 
            WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.No_Investigation_Required_On__c);

        objInvestigation.CMPL123_WF_Action__c = 'Reject';
        objInvestigation.Rejection_Rationale__c = 'test';
        objInvestigation.Rejection_Reason__c = 'test';
        update objInvestigation;
        objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, Rejected_On__c
        FROM CMPL123CME__Investigation__c 
            WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.Rejected_On__c);

        objInvestigation.CMPL123_WF_Action__c = 'Reopen - Go To Conclude';
        update objInvestigation;
        objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, Reopened_On__c
        FROM CMPL123CME__Investigation__c 
            WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.Reopened_On__c);

        Test.stopTest();
    }

    /*
    * @Method       : wfActionFieldsUpdateTest2
    * @Description  : Tests migrated WF Rules logic related to WF Action updates
    * @Return       : N/A
    * @Params       : N/A
    */
    @isTest
    static void wfActionFieldsUpdateTest2(){
        Test.startTest();
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, Division__c, CMPL123CME__Complaint__c FROM CMPL123CME__Investigation__c LIMIT 1];
        
        System.assertEquals('ADD', objInvestigation.Division__c);
        Product_Ticket__c productTicket = [
            SELECT Id FROM Product_Ticket__c
            WHERE Event_Ticket__c = :objInvestigation.CMPL123CME__Complaint__c
            AND Batch_Lot_Serial__c = :PT_BATCH_LOT_NUM1];
        Product_Lot__c productLot = (Product_Lot__c) TestDataFactory.createSObject(
            new Product_Lot__c(
                Product_Evaluation_Investigation__c = objInvestigation.Id,
                Related_Ticket__c = objInvestigation.CMPL123CME__Complaint__c,
                Product_Name__c = productTicket.Id
            ), true);
        objInvestigation.CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId();
        objInvestigation.CMPL123_WF_Action__c = 'Send Back to Evaluation';
        update objInvestigation;
        CMPL123CME__Investigation__c objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, Sent_to_Evaluation_On__c
                                                                    FROM CMPL123CME__Investigation__c 
                                                                        WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.Sent_to_Evaluation_On__c);
        
        objInvestigation.CMPL123_WF_Action__c = 'Send Back to Investigation';
        update objInvestigation;
        objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, Sent_to_Investigation_On__c
        FROM CMPL123CME__Investigation__c 
            WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.Sent_to_Investigation_On__c);

        objInvestigation.CMPL123_WF_Action__c = 'Submit for Evaluation';
        update objInvestigation;
        objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, Submitted_for_Evaluation_On__c
        FROM CMPL123CME__Investigation__c 
            WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.Submitted_for_Evaluation_On__c);

        objInvestigation.CMPL123_WF_Action__c = 'Submit for Investigation';
        update objInvestigation;
        objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, Submitted_for_Investigation_On__c
        FROM CMPL123CME__Investigation__c 
            WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.Submitted_for_Investigation_On__c);

        objInvestigation.CMPL123_WF_Action__c = 'Submit for Review';
        update objInvestigation;
        objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, Submitted_for_Review_On__c
        FROM CMPL123CME__Investigation__c 
            WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.Submitted_for_Review_On__c);

        objInvestigation.CMPL123_WF_Action__c = 'Void';
        update objInvestigation;
        objInvestigationUpdated = [SELECT CMPL123_WF_Action_Performed_On__c, Voided_On__c
        FROM CMPL123CME__Investigation__c 
            WHERE Id = :objInvestigation.Id];
        System.assertEquals(objInvestigationUpdated.CMPL123_WF_Action_Performed_On__c, objInvestigationUpdated.Voided_On__c);

        Test.stopTest();
    }

    /*
    * @Method       : autosetRegistrationNumberTest
    * @Description  : Tests migrated WF Rules logic related to autoseting Registration Number field
    * @Return       : N/A
    * @Params       : N/A
    */
    @isTest
    static void autosetRegistrationNumberTest(){
          
        ADD_App_Settings__c appSetting = new ADD_App_Settings__c();
        appSetting.Restrict_Workflow_Updates__c = false;
        appSetting.Name = 'User';
        appSetting.Restrict_Triggers__c = false;
        appSetting.Restrict_Validation_Rules__c = true;
        insert appSetting;
        Test.startTest();
        // Create Service
        String serviceRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Service').getRecordTypeId();
        User user = [SELECT Id, UserName FROM User WHERE UserName LIKE 'cei@test.com%' LIMIT 1];
        CMPL123CME__Complaint__c service = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
               Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'INDIA',
                RecordTypeId = serviceRTId,
                Business_Unit__c = 'IA-CC',
                Ticket_Type__c = 'Service',
                Service_Type__c = 'Planned',
                Is_Product_Evaluation_Investigation_chil__c = false,
                CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                CMSNext_Ticket_Number__c = CMSNEXT_NUM_ONE
            ), true);
        CMPL123CME__Investigation__c objInv = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
            new CMPL123CME__Investigation__c(
                Assessor__c = user.Id,
                Evaluator_Investigator__c = user.Id,
                Conclusion_Summary__c = 'Test',
                Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction,
                Product_Evaluation_Type__c = 'Lot to lot variability',
                Approver__c = [SELECT Id FROM User WHERE Username LIKE 'hiii12@test.com%' LIMIT 1].Id,
                Additional_Action_Taken__c = 'No',
                Close_to_Threshold__c = 'Yes',
                Prod_Eval_Returns_to_be_Requested__c = 'No',
                Not_Requested_Rationale__c = 'Test',
                CMPL123CME__Complaint__c = service.Id
            ), true);
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, Registration_Number__c
                                                            FROM CMPL123CME__Investigation__c 
                                                                WHERE CMPL123CME__Complaint__c = :service.Id];
        String registrationNumberExpected = service.CMSNext_Ticket_Number__c + '(' + service.Service_Type__c + ' ' 
            + 'Service' + ')';
        System.assertEquals(registrationNumberExpected, objInvestigation.Registration_Number__c);
        Test.stopTest();
    }

    /*
    * @Method       : cycleTimeTest
    * @Description  : Tests migrated WF Rules logic related to cycle time updates
    * @Return       : N/A
    * @Params       : N/A
    */
    @isTest
    static void cycleTimeTest(){
        Test.startTest();
        Double MS_IN_DAY = 86400000;
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123CME__Complaint__c FROM CMPL123CME__Investigation__c LIMIT 1];
        Product_Ticket__c productTicket = [
            SELECT Id FROM Product_Ticket__c
            WHERE Event_Ticket__c = :objInvestigation.CMPL123CME__Complaint__c
            AND Batch_Lot_Serial__c = :PT_BATCH_LOT_NUM1];
        Product_Lot__c productLot = (Product_Lot__c) TestDataFactory.createSObject(
            new Product_Lot__c(
                Product_Evaluation_Investigation__c = objInvestigation.Id,
                Related_Ticket__c = objInvestigation.CMPL123CME__Complaint__c,
                Product_Name__c = productTicket.Id
            ), true);
        DateTime reopenedOn = DateTime.newInstance(2021, 01, 12, 01, 35, 20);
        DateTime approvedOn = DateTime.newInstance(2021, 01, 11, 02, 45, 30);

        objInvestigation.Reopened_On__c = reopenedOn;
        objInvestigation.Approved_On__c = approvedOn;
        objInvestigation.Reopened_Date__c = reopenedOn.date();
        objInvestigation.Closed_Date__c = approvedOn.date();
        update objInvestigation;
        CMPL123CME__Investigation__c objInvestigationUpdated = [SELECT Cycle_Time__c
                                                                    FROM CMPL123CME__Investigation__c 
                                                                        WHERE Id = :objInvestigation.Id];
        Double cycleTimeDays = (reopenedOn.getTime() - approvedOn.getTime())/MS_IN_DAY;
        // DDS2 Update Cycle Time WF Rule test
        System.assertEquals(cycleTimeDays, objInvestigationUpdated.Cycle_Time__c);
        Test.stopTest();
    }
    
    /*
    * @Method       : cycleTimeTest
    * @Description  : Tests migrated WF Rules logic related to cycle time updates
    * @Return       : N/A
    * @Params       : N/A
    */
    @isTest
    static void searchableFieldTest(){
        Test.startTest();
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123CME__Complaint__c FROM CMPL123CME__Investigation__c LIMIT 1];
        Map <Id, Ticket_Product_Evaluation_Investigation__c> prodEvalInvs = new Map <Id, Ticket_Product_Evaluation_Investigation__c>(
                [SELECT LastModifiedDate, Searchable__c
                    FROM Ticket_Product_Evaluation_Investigation__c 
                        WHERE Investigation_Evaluation__c = :objInvestigation.Id]
        );
        
        // Checks searchable field populating upon Prod Eval insert 
        System.assertEquals(true, prodEvalInvs.values().get(0)?.Searchable__c != null);
        
        objInvestigation.Voided_Rationale__c = 'test';
        update objInvestigation;
        
        List <Ticket_Product_Evaluation_Investigation__c> prodEvalInvsUpdated = [SELECT LastModifiedDate, Searchable__c 
                FROM Ticket_Product_Evaluation_Investigation__c 
                    WHERE Investigation_Evaluation__c = :objInvestigation.Id];

        // Checks LastMofifiedDate upon Prod Eval not valuable field update 
        System.assertEquals(true, prodEvalInvs.get(prodEvalInvsUpdated[0]?.Id)?.LastModifiedDate == prodEvalInvsUpdated[0]?.LastModifiedDate);

        objInvestigation.Product_List_Numbers__c = '123';
        update objInvestigation;

        prodEvalInvsUpdated = [
            SELECT LastModifiedDate, Searchable__c
            FROM Ticket_Product_Evaluation_Investigation__c 
            WHERE Investigation_Evaluation__c = :objInvestigation.Id
        ];
        // Checks searchable field updating upon Prod Eval valuable field update 
        System.assertEquals(true, prodEvalInvs.get(prodEvalInvsUpdated[0]?.Id)?.Searchable__c != prodEvalInvsUpdated[0]?.Searchable__c);

        Test.stopTest();
    }

    private static CMPL123CME__Complaint__c queryForTicketAndChildren() {
        return queryForTicketAndChildren(CMSNEXT_NUM_ONE);
    }

    /**
     * Helper fn that queries for the Ticket and its children
     * @author 28-NOV-2022 Larry
     * @revision 31-MAY-2023 Larry: Now gets MedEval children as well
     */
    private static CMPL123CME__Complaint__c queryForTicketAndChildren(String cmsNextNum) {
        return [
            SELECT Id, Complaint_Quality_Closure_Date__c,
            // Fetches the ProdEval children
            (
                SELECT Id,
                CMPL123_WF_Status__c,
                // The four fields below are "cumulative fields"
                Product_Lot_Numbers__c,
                Product_List_Numbers__c,
                Products__c,
                Has_Product_Lot_Child__c,
                Conclusion_Disposition__c
                FROM CMPL123CME__Investigations__r
                // With the proper WorkFlow records inserted into the org,
                // ProdEvals actually start in the 'Assess' WF_Status instead
                // of null. The "system-generated ProdEval" will have a null
                // WF_Status because of this missing piece of testSetup data.
                WHERE CMPL123_WF_Status__c != null
            ),
            // Fetches the Product-Ticket children
            (
                SELECT Id,
                Product__c,
                // The three fields below contribute to ProdEval "cumulative fields"
                Batch_Lot_Serial__c,
                Product_List_Number__c,
                Product_Name__c
                FROM Products_Events__r
                WHERE Likely_Cause__c = :AspenConstants.STR_Yes
                AND Delete_Flag__c = false
                AND Product__c != null
            ),
            // Fetches the MedEval children
            (
                SELECT Id, Follow_Up_Awareness_Date__c,
                Conclusion_Disposition_Flag__c, CMPL123_WF_Status__c,
                Reportability__c, LastModifiedDate,
                CMPL123CME__Key_value__c
                FROM CMPL123CME__Questionnaires__r
            )
            FROM CMPL123CME__Complaint__c
            WHERE CMSNext_Ticket_Number__c = :cmsNextNum
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }

    /**
     * Helper for verifying tests related to cumulative fields.
     * 
     * It is harmless to have duplicate values or inconsistent ordering
     * in the cumulative fields because these fields are used for searching
     * and filtering purposes. This function normalizes a cumulative field
     * so that it can be compared against another cumulative field.
     * @author 29-NOV-2022 Larry
     */
    private static Set<String> getUniqueValuesInCsv(String csv) {
        return new Set<String>(csv.split(','));
    }

    /**
     * Tests for setCumulsOnEachProdEval when activated from Product-Ticket
     * 
     * Updating a Product-Ticket can subsequently update a ProdEval's
     * cumulative fields. When this happens, the ProdEval's own trigger should
     * accept the cumulative fields as-is instead of recalculating the fields.
     * This function verifies that the recalculation is avoided.
     * If a recalc happens, you will witness the cumulative fields get
     * effectively reverted as though the Product-Ticket trigger did not
     * change any ProdEvals.
     * @author 29-NOV-2022 Larry
     */
    @isTest
    static void testSetCumulsOnEachProdEvalFromProductTicket() {
        final String PT_BATCH_LOT_NUM_NEW = 'FWEEE';
        User aspenUser = [SELECT Id FROM User WHERE Username LIKE 'aspenUserTest@test.com.test%' LIMIT 1];
        System.runAs(aspenUser) {
            // Fetch data we will work with
            CMPL123CME__Complaint__c ticket = queryForTicketAndChildren();
            System.assert(!ticket.Products_Events__r.isEmpty(),
                'Test Setup Bug: No Product-Tickets can be used for this test');
            System.assert(!ticket.CMPL123CME__Investigations__r.isEmpty(),
                'Test Setup Bug: No ProdEvals can be used for this test');

            // Track what the cumulative fields are originally set to
            Map<Id, CMPL123CME__Investigation__c> prodEvalIdToRecordOld =
                new Map<Id, CMPL123CME__Investigation__c>();
            for (CMPL123CME__Investigation__c prodEval : ticket.CMPL123CME__Investigations__r) {
                prodEvalIdToRecordOld.put(prodEval.Id, prodEval);
                System.assert(AspenConstants.OPEN_WF_STATUSES_PRODEVAL.get(true).contains(prodEval.CMPL123_WF_Status__c),
                    'Test Setup Bug: ' + prodEval.CMPL123_WF_Status__c + ' is not an "open" ProdEval status');
                System.assertNotEquals(null, prodEval.Product_Lot_Numbers__c,
                    'Test Setup Bug: All ProdEvals should start with the Lot Numbers cumulative field filled in');
            }

            // Make a change that would affect the cumulative fields.
            // Note: To update List # or Product Name, update a Product, then
            // update the Product-Tickets that reference that Product.
            // Product-Tickets update cumulative fields, but Products do not.
            Product_Ticket__c productTicketJunc = ticket.Products_Events__r[0];
            productTicketJunc.Batch_Lot_Serial__c = PT_BATCH_LOT_NUM_NEW;
            Test.startTest();
            update productTicketJunc;
            Test.stopTest();

            // Verify that cumulative fields were affected for all ProdEvals under
            // the ticket that had one of its Product-Ticket children changed
            ticket = queryForTicketAndChildren();
            for (CMPL123CME__Investigation__c prodEvalNew : ticket.CMPL123CME__Investigations__r) {
                CMPL123CME__Investigation__c prodEvalOld = prodEvalIdToRecordOld.get(prodEvalNew.Id);
                System.assertNotEquals(prodEvalOld.Product_Lot_Numbers__c, prodEvalNew.Product_Lot_Numbers__c,
                    'Pos test fail: The Product Lot Numbers cumulative field did not update');
                {
                    Set<String> cumulListNumsOld = getUniqueValuesInCsv(prodEvalOld.Product_List_Numbers__c);
                    Set<String> cumulListNumsNew = getUniqueValuesInCsv(prodEvalNew.Product_List_Numbers__c);
                    System.assert(cumulListNumsOld.containsAll(cumulListNumsNew),
                        'Pos test fail: The Product List Numbers cumulative field was supposed to refresh but not change');
                    System.assertEquals(cumulListNumsOld.size(), cumulListNumsNew.size(),
                        'Pos test fail: The Product List Numbers cumulative field was supposed to refresh but not change');
                }
                {
                    Set<String> cumulProductNamesOld = getUniqueValuesInCsv(prodEvalOld.Products__c);
                    Set<String> cumulProductNamesNew = getUniqueValuesInCsv(prodEvalNew.Products__c);
                    System.assert(cumulProductNamesOld.containsAll(cumulProductNamesNew),
                        'Pos test fail: The Product Names cumulative field was supposed to refresh but not change');
                    System.assertEquals(cumulProductNamesOld.size(), cumulProductNamesNew.size(),
                        'Pos test fail: The Product Names cumulative field was supposed to refresh but not change');
                }
                System.assertEquals(prodEvalOld.Has_Product_Lot_Child__c, prodEvalNew.Has_Product_Lot_Child__c,
                    'Pos test fail: The Has Product/Lot Child flag was supposed to refresh but not change');
            }
        } // end of System.runAs(aspenUser)
    }

    /**
     * Pos tests for setCumulsOnEachProdEval when activated from ProdEval
     * @author 29-NOV-2022 Larry
     */
    @isTest
    static void testSetCumulsOnEachProdEvalFromProdEval() {
        final String ERR_EXPECT_PASSTHRU =
            'Pos test fail: Direct changes to cumulative fields should be applied';
        final String LOT_NUM_NEW = 'FWEEE';
        final String LIST_NUM_NEW = 'WAOOH';
        final String PRODUCT_NAME_NEW = 'YIPEEE';
        User aspenUser = [SELECT Id FROM User WHERE Username LIKE 'aspenUserTest@test.com.test%' LIMIT 1];
        System.runAs(aspenUser) {
            // Fetch data we will work with
            CMPL123CME__Complaint__c ticket = queryForTicketAndChildren();
            System.assert(!ticket.Products_Events__r.isEmpty(),
                'Test Setup Bug: No Product-Tickets can be used for this test');
            System.assert(!ticket.CMPL123CME__Investigations__r.isEmpty(),
                'Test Setup Bug: No ProdEvals can be used for this test');

            // Track what the cumulative fields are originally set to
            Map<Id, CMPL123CME__Investigation__c> prodEvalIdToRecordOld =
                new Map<Id, CMPL123CME__Investigation__c>();
            CMPL123CME__Investigation__c prodEvalOld;
            for (CMPL123CME__Investigation__c prodEval : ticket.CMPL123CME__Investigations__r) {
                prodEvalIdToRecordOld.put(prodEval.Id, prodEval);
                System.assert(AspenConstants.OPEN_WF_STATUSES_PRODEVAL.get(true).contains(prodEval.CMPL123_WF_Status__c),
                    'Test Setup Bug: ' + prodEval.CMPL123_WF_Status__c + ' is not an "open" ProdEval status');
                System.assertNotEquals(null, prodEval.Product_Lot_Numbers__c,
                    'Test Setup Bug: All ProdEvals should start with the Lot Numbers cumulative field filled in');
                // Take any one of the ProdEval children for modification
                prodEvalOld = prodEval;
            }

            // Try editing cumulative fields directly
            prodEvalOld.Product_Lot_Numbers__c = LOT_NUM_NEW;
            prodEvalOld.Product_List_Numbers__c = LIST_NUM_NEW;
            prodEvalOld.Products__c = PRODUCT_NAME_NEW;
            Test.startTest();
            update prodEvalOld;
            Test.stopTest();

            // Verify that cumulative fields assignments were accepted and unchanged
            ticket = queryForTicketAndChildren();
            // Fetch the ProdEval that we just updated
            CMPL123CME__Investigation__c prodEvalNew;
            for (CMPL123CME__Investigation__c prodEvalTemp : ticket.CMPL123CME__Investigations__r) {
                if (prodEvalTemp.Id == prodEvalOld.Id) {
                    prodEvalNew = prodEvalTemp;
                    break;
                }
            }
            System.assertEquals(LOT_NUM_NEW, prodEvalNew.Product_Lot_Numbers__c, ERR_EXPECT_PASSTHRU);
            System.assertEquals(LIST_NUM_NEW, prodEvalNew.Product_List_Numbers__c, ERR_EXPECT_PASSTHRU);
            System.assertEquals(PRODUCT_NAME_NEW, prodEvalNew.Products__c, ERR_EXPECT_PASSTHRU);
            System.assertEquals(prodEvalOld.Has_Product_Lot_Child__c, prodEvalNew.Has_Product_Lot_Child__c,
                'Pos test fail: The Has Product/Lot Child flag should not change');
        } // end of System.runAs(aspenUser)
    }

    /**
     * Neg tests for setCumulsOnEachProdEval when activated from ProdEval
     * @author 29-NOV-2022 Larry
     */
    @isTest
    static void testSetCumulsOnEachProdEvalFromProdEvalNeg() {
        final String ERR_EXPECT_NO_SOQL = 'Neg test fail: Should not query for more data';
        final String ERR_EXPECT_NO_DML = 'Neg test fail: Should not cause changes';
        final String ERR_RETURN_LIST = 'Neg test fail: Should always return a List';
        final String ERR_EXPECT_PASSTHRU =
            'Pos test fail: Direct changes to cumulative fields should be applied';
        final String LOT_NUM_NEW = 'FWEEE';
        final String LIST_NUM_NEW = 'WAOOH';
        final String PRODUCT_NAME_NEW = 'YIPEEE';
        User aspenUser = [SELECT Id FROM User WHERE Username LIKE 'aspenUserTest@test.com.test%' LIMIT 1];
        System.runAs(aspenUser) {
            // Fetch data we will work with
            CMPL123CME__Complaint__c ticket = queryForTicketAndChildren();
            System.assert(!ticket.Products_Events__r.isEmpty(),
                'Test Setup Bug: No Product-Tickets can be used for this test');
            System.assert(!ticket.CMPL123CME__Investigations__r.isEmpty(),
                'Test Setup Bug: No ProdEvals can be used for this test');

            // Track what the cumulative fields are originally set to
            Map<Id, CMPL123CME__Investigation__c> prodEvalIdToRecordOld =
                new Map<Id, CMPL123CME__Investigation__c>();
            for (CMPL123CME__Investigation__c prodEval : ticket.CMPL123CME__Investigations__r) {
                prodEvalIdToRecordOld.put(prodEval.Id, prodEval);
            }

            Test.startTest();
            List<Id> result;
            Integer numDml = Limits.getDMLStatements();
            Integer numSoql = Limits.getQueries();

            // Invalid scenario: Trigger.oldMap is set, but Trigger.new is null or empty
            result = ADDInvestigationHandler.setCumulsOnEachProdEval(prodEvalIdToRecordOld, null);
            System.assertEquals(numDml, Limits.getDMLStatements(), ERR_EXPECT_NO_DML);
            System.assertEquals(numSoql, Limits.getQueries(), ERR_EXPECT_NO_SOQL);
            System.assertNotEquals(null, result, ERR_RETURN_LIST);
            System.assert(result.isEmpty(), ERR_EXPECT_NO_DML);

            // Invalid scenario: Trigger.oldMap and Trigger.new are null or empty
            result = ADDInvestigationHandler.setCumulsOnEachProdEval(null, null);
            System.assertEquals(numDml, Limits.getDMLStatements(), ERR_EXPECT_NO_DML);
            System.assertEquals(numSoql, Limits.getQueries(), ERR_EXPECT_NO_SOQL);
            System.assertNotEquals(null, result, ERR_RETURN_LIST);
            System.assert(result.isEmpty(), ERR_EXPECT_NO_DML);
            Test.stopTest();
        } // end of System.runAs(aspenUser)
    }

    /**
     * Tests for chooseHighestPriority to make sure the highest priority investigation conclusion is returned
     * @author 19-JAN-2023 Danny
     */
    @isTest
    static void testChooseHighestPriority() {
        // Investigation Conclusions for Medical Devices from Highest to Lowest Priority
        // 80067 Deficiency, Malfunction
        // 80064 NO Deficiency, Malfunction
        // 80065 NO Deficiency, Malfunction, Manufacturing Defect/Distribution Issue
        // 80066 NO Deficiency, NO Malfunction

        // Investigation Conclusions for Non-Medical Devices from Highest to Lowest Priority
        // 80069 Non-Medical Device, Product Problem
        // 80068 Non-Medical Device, NO Product Problem

        String currentInvestigationConclusion;
        String newInvestigationConclusion;
        String result;
        
        Test.startTest();

        // Going up in priority
        currentInvestigationConclusion = AspenConstants.STR_80068_Non_Medical_Device_NO_Product_Problem;
        newInvestigationConclusion = AspenConstants.STR_80069_Non_Medical_Device_Product_Problem;
        result = ADDInvestigationHandler.chooseHighestPriority(currentInvestigationConclusion, newInvestigationConclusion);
        System.assertEquals(AspenConstants.STR_80069_Non_Medical_Device_Product_Problem, result , 'positive test fail: expected result is 80069');

        // Going down in priority
        currentInvestigationConclusion = AspenConstants.STR_80064_NO_Deficiency_Malfunction;
        newInvestigationConclusion = AspenConstants.STR_80065_NO_Deficiency_Malfunction_Defect_Distribution_Issue;
        result = ADDInvestigationHandler.chooseHighestPriority(currentInvestigationConclusion, newInvestigationConclusion);
        System.assertEquals(AspenConstants.STR_80064_NO_Deficiency_Malfunction, result, 'positive test fail: expected result is 80064');

        // Negative test: null
        currentInvestigationConclusion = null;
        newInvestigationConclusion = AspenConstants.STR_80069_Non_Medical_Device_Product_Problem;
        result = ADDInvestigationHandler.chooseHighestPriority(currentInvestigationConclusion, newInvestigationConclusion);
        System.assertEquals(AspenConstants.STR_80069_Non_Medical_Device_Product_Problem, result, 'negative test fail: expected result is 80069');

        Test.stopTest();
    }

    /**
     * Accessibility test for updateMedEvals
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateMedEvalsFull() {
        final String CONC_CODE = AspenConstants.STR_80064_CODE;
        final String THIS_CMSNEXT_NUM = CMSNEXT_NUM_80064_WITH_MEDEVAL;

        CMPL123CME__Complaint__c ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        Assert.isFalse(ticket.CMPL123CME__Questionnaires__r.isEmpty(),
            ERROR_SETUP + 'The Ticket needs MedEval(s) to test this function');
        Assert.isFalse(ticket.CMPL123CME__Investigations__r.isEmpty(),
            ERROR_SETUP + 'The Ticket needs ProdEval(s) to test this function');

        Test.startTest();
        // Access updateMedEvals as part of a trigger context
        CMPL123CME__Investigation__c prodEval = ticket.CMPL123CME__Investigations__r[0];
        prodEval.CMPL123_WF_Status__c = AspenConstants.STR_Closed_Done;
        prodEval.Conclusion_Disposition__c = AspenConstants.STR_80067_Deficiency_Malfunction;
        update prodEval;
        Test.stopTest();

        ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        for (CMPL123CME__Questionnaire__c medEval : ticket.CMPL123CME__Questionnaires__r) {
            if (medEval.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Voided) {
                // This test does not apply to voided MedEvals
                continue;
            }
            Assert.areEqual(AspenConstants.STR_Deficiency, medEval.Conclusion_Disposition_Flag__c,
                ERROR_POS + 'Did not reach updateMedEvals?');
        }
    }

    /**
     * Pos test for updateMedEvalsGetWfStepsForProcessEval
     * 
     * The function we are testing is intended to never fail...
     * This test method is mainly for our setup data
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateMedEvalsGetWfStepsForProcessEval() {
        Assert.areEqual(2, ADDInvestigationHandler.updateMedEvalsGetWfStepsForProcessEval().size(), ERROR_SETUP +
            'Should have gotten the two WorkFlow Steps that go to "In Process Evaluation" made in testSetup');
    }

    /**
     * Neg tests for updateMedEvals where input parameters are unusable
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateMedEvalsNeg() {
        Test.startTest();
        Integer numSoqlBefore = Limits.getQueries();
        ADDInvestigationHandler.updateMedEvals(new Map<Id, Id>());
        Integer numSoqlAfter = Limits.getQueries();
        Assert.areEqual(numSoqlAfter, numSoqlBefore,
            ERROR_NEG + 'Should not query anything if the input is empty');
        Test.stopTest();
    }

    /**
     * Pos tests for updateMedEvals where Tickets w/code 80064 DO have MedEval children
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateMedEvalsWithChildren80064() {
        final String CONC_CODE = AspenConstants.STR_80064_CODE;
        final String THIS_CMSNEXT_NUM = CMSNEXT_NUM_80064_WITH_MEDEVAL;

        CMPL123CME__Complaint__c ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        Assert.isFalse(ticket.CMPL123CME__Questionnaires__r.isEmpty(),
            ERROR_SETUP + 'The Ticket needs MedEval(s) to test this function');
        Assert.areEqual(1, ticket.CMPL123CME__Investigations__r.size(),
            ERROR_SETUP + 'The Ticket needs exactly one ProdEval to test this function');
        Assert.areEqual(AspenConstants.STR_80064_NO_Deficiency_Malfunction,
            ticket.CMPL123CME__Investigations__r[0].Conclusion_Disposition__c,
            ERROR_SETUP + 'The ProdEval needs Conclusion Disposition code ' + CONC_CODE);

        // Track the current MedEvals to see which ones get updated and how
        Map<Id, CMPL123CME__Questionnaire__c> medEvalIdToOldRec =
            new Map<Id, CMPL123CME__Questionnaire__c>();
        for (CMPL123CME__Questionnaire__c medEval : ticket.CMPL123CME__Questionnaires__r) {
            medEvalIdToOldRec.put(medEval.Id, medEval);
        }

        // Gather ProdEval Ids to call the function we are testing
        Map<Id, Id> prodEvalIdToTicketId = new Map<Id, Id>();
        for (CMPL123CME__Investigation__c prodEval : ticket.CMPL123CME__Investigations__r) {
            prodEvalIdToTicketId.put(prodEval.Id, ticket.Id);
        }

        Test.startTest();
        ADDInvestigationHandler.updateMedEvals(prodEvalIdToTicketId);
        Test.stopTest();

        ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        for (CMPL123CME__Questionnaire__c medEvalNew : ticket.CMPL123CME__Questionnaires__r) {
            final String FOR_WHAT = ' for code ' + CONC_CODE +
                ' and WorkFlow Status ' + medEvalNew.CMPL123_WF_Status__c;
            CMPL123CME__Questionnaire__c medEvalOld = medEvalIdToOldRec.get(medEvalNew.Id);

            if (medEvalNew.CMPL123_WF_Status__c == AspenConstants.STR_WF_Opened ||
                medEvalNew.CMPL123_WF_Status__c == AspenConstants.STR_In_Process_Evaluation
            ) {
                // Verify that fields are assigned correctly
                Assert.areEqual(AspenConstants.STR_Malfunction_Requiring_Med_Eval,
                    medEvalNew.Conclusion_Disposition_Flag__c,
                    ERROR_POS + 'Conclusion Disposition Flag is not set correctly' + FOR_WHAT);
                Assert.areEqual(AspenConstants.POTENTIAL_REPORTABLE_EVENT, medEvalNew.CMPL123CME__Key_value__c,
                    ERROR_POS + 'Key Value is not set correctly' + FOR_WHAT);
            } else if (medEvalNew.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Done ||
                medEvalNew.CMPL123_WF_Status__c == AspenConstants.STR_Regulatory ||
                medEvalNew.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Voided
            ) {
                // Verify that this MedEval was untouched
                Assert.areEqual(medEvalOld.LastModifiedDate,
                    medEvalNew.LastModifiedDate,
                    ERROR_POS + 'MedEval should NOT be updated' + FOR_WHAT);
            } else {
                Assert.fail('Unexpected bug: This MedEval has a WorkFlow Status that is not part of testing: ' +
                    medEvalNew.CMPL123_WF_Status__c);
            }
        }
    }

    /**
     * Pos tests for updateMedEvals where Tickets w/code 80067 DO have MedEval children
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateMedEvalsWithChildren80067() {
        final String CONC_CODE = AspenConstants.STR_80067_CODE;
        final String THIS_CMSNEXT_NUM = CMSNEXT_NUM_80067_WITH_MEDEVAL;

        CMPL123CME__Complaint__c ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        Assert.isFalse(ticket.CMPL123CME__Questionnaires__r.isEmpty(),
            ERROR_SETUP + 'The Ticket needs MedEval(s) to test this function');
        Assert.areEqual(1, ticket.CMPL123CME__Investigations__r.size(),
            ERROR_SETUP + 'The Ticket needs exactly one ProdEval to test this function');
        Assert.areEqual(AspenConstants.STR_80067_Deficiency_Malfunction,
            ticket.CMPL123CME__Investigations__r[0].Conclusion_Disposition__c,
            ERROR_SETUP + 'The ProdEval needs Conclusion Disposition code ' + CONC_CODE);

        // Track the current MedEvals to see which ones get updated and how
        List<Id> medEvalIdsWithWfHistory = new List<Id>();
        Map<Id, CMPL123CME__Questionnaire__c> medEvalIdToOldRec =
            new Map<Id, CMPL123CME__Questionnaire__c>();
        for (CMPL123CME__Questionnaire__c medEval : ticket.CMPL123CME__Questionnaires__r) {
            medEvalIdToOldRec.put(medEval.Id, medEval);
            if (ADDInvestigationHandler.MEDEVAL_WFSTATUS_TO_IN_PROCESS.contains(
                medEval.CMPL123_WF_Status__c)
            ) {
                medEvalIdsWithWfHistory.add(medEval.Id);
            }
        }

        Integer numWfHistoriesBefore = [SELECT COUNT() FROM CMPL123__WF_History__c
            WHERE CMPL123__Related_Id__c IN :medEvalIdsWithWfHistory];

        // Gather ProdEval Ids to call the function we are testing
        Map<Id, Id> prodEvalIdToTicketId = new Map<Id, Id>();
        for (CMPL123CME__Investigation__c prodEval : ticket.CMPL123CME__Investigations__r) {
            prodEvalIdToTicketId.put(prodEval.Id, ticket.Id);
        }

        Test.startTest();
        ADDInvestigationHandler.updateMedEvals(prodEvalIdToTicketId);
        Test.stopTest();

        // Verify field assignments for MedEvals
        ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        for (CMPL123CME__Questionnaire__c medEvalNew : ticket.CMPL123CME__Questionnaires__r) {
            final String FOR_WHAT = ' for code ' + CONC_CODE +
                ' and WorkFlow Status ' + medEvalNew.CMPL123_WF_Status__c;
            CMPL123CME__Questionnaire__c medEvalOld = medEvalIdToOldRec.get(medEvalNew.Id);

            if (medEvalOld.CMPL123_WF_Status__c == AspenConstants.STR_WF_Opened ||
                medEvalOld.CMPL123_WF_Status__c == AspenConstants.STR_In_Process_Evaluation
            ) {
                // Verify that fields are assigned correctly
                Assert.areEqual(AspenConstants.STR_Deficiency,
                    medEvalNew.Conclusion_Disposition_Flag__c,
                    ERROR_POS + 'Conclusion Disposition Flag is not set correctly' + FOR_WHAT);
                Assert.areEqual(AspenConstants.STR_Deficiency, medEvalNew.CMPL123CME__Key_value__c,
                    ERROR_POS + 'Key Value is not set correctly' + FOR_WHAT);
            } else if (ADDInvestigationHandler.MEDEVAL_WFSTATUS_TO_IN_PROCESS.contains(
                medEvalOld.CMPL123_WF_Status__c)
            ) {
                // Verify that fields are assigned correctly
                Assert.areNotEqual(medEvalOld.LastModifiedDate,
                    medEvalNew.LastModifiedDate,
                    ERROR_POS + 'MedEval SHOULD be updated' + FOR_WHAT);
                Assert.areEqual(AspenConstants.STR_In_Process_Evaluation,
                    medEvalNew.CMPL123_WF_Status__c,
                    ERROR_POS + 'MedEval should go back to the In Process status' + FOR_WHAT +
                    '. This might be a setup bug. Does the WorkFlow STEP exist?');
                Assert.areEqual(AspenConstants.STR_Deficiency,
                    medEvalNew.Conclusion_Disposition_Flag__c,
                    ERROR_POS + 'Conclusion Disposition Flag is not set correctly' + FOR_WHAT);
                Assert.areEqual(medEvalOld.Follow_Up_Awareness_Date__c,
                    medEvalNew.Follow_Up_Awareness_Date__c,
                    ERROR_POS + 'Follow-up Awareness Date should be unchanged' + FOR_WHAT);
            } else if (medEvalOld.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Voided) {
                // Verify that this MedEval was untouched
                Assert.areEqual(medEvalOld.LastModifiedDate,
                    medEvalNew.LastModifiedDate,
                    ERROR_POS + 'MedEval should NOT be updated' + FOR_WHAT);
            } else {
                Assert.fail('Unexpected bug: This MedEval has a WorkFlow Status that is not part of testing: ' +
                    medEvalNew.CMPL123_WF_Status__c);
            }
        }

        // Verify WorkFlow History creation
        Integer numWfHistoriesAfter = [SELECT COUNT() FROM CMPL123__WF_History__c
            WHERE CMPL123__Related_Id__c IN :medEvalIdsWithWfHistory];
        Assert.areEqual(ADDInvestigationHandler.MEDEVAL_WFSTATUS_TO_IN_PROCESS.size(),
            numWfHistoriesAfter - numWfHistoriesBefore,
            ERROR_POS + 'Should make one new WorkFlow History for each relevant WorkFlow Status');
    }

    /**
     * Pos tests for updateMedEvals where Tickets w/code 80064 do NOT have MedEval children
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateMedEvalsNoChildren80064() {
        final String CONC_CODE = AspenConstants.STR_80064_CODE;
        final String THIS_CMSNEXT_NUM = CMSNEXT_NUM_80064_NO_MEDEVAL;

        CMPL123CME__Complaint__c ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        Assert.isTrue(ticket.CMPL123CME__Questionnaires__r.isEmpty(),
            ERROR_SETUP + 'The Ticket needs NO MedEvals to test this function');
        Assert.areEqual(1, ticket.CMPL123CME__Investigations__r.size(),
            ERROR_SETUP + 'The Ticket needs exactly one ProdEval to test this function');
        Assert.areEqual(AspenConstants.STR_80064_NO_Deficiency_Malfunction,
            ticket.CMPL123CME__Investigations__r[0].Conclusion_Disposition__c,
            ERROR_SETUP + 'The ProdEval needs Conclusion Disposition code ' + CONC_CODE);

        // Gather ProdEval Ids to call the function we are testing
        Map<Id, Id> prodEvalIdToTicketId = new Map<Id, Id>();
        for (CMPL123CME__Investigation__c prodEval : ticket.CMPL123CME__Investigations__r) {
            prodEvalIdToTicketId.put(prodEval.Id, ticket.Id);
        }

        Test.startTest();
        ADDInvestigationHandler.updateMedEvals(prodEvalIdToTicketId);
        Test.stopTest();

        ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        Assert.areEqual(1, ticket.CMPL123CME__Questionnaires__r.size(),
            ERROR_POS + 'A MedEval should have been created');
        CMPL123CME__Questionnaire__c medEval = ticket.CMPL123CME__Questionnaires__r[0];
        Assert.areEqual(AspenConstants.POTENTIAL_REPORTABLE_EVENT, medEval.CMPL123CME__Key_value__c,
            ERROR_POS + 'Wrong KeyValue for the new MedEval');
        Assert.areEqual(AspenConstants.STR_Malfunction_Requiring_Med_Eval,
            medEval.Conclusion_Disposition_Flag__c,
            ERROR_POS + 'Wrong Conclusion Disposition Flag for the new MedEval');
    }

    /**
     * Pos tests for updateMedEvals where Tickets w/code 80067 do NOT have MedEval children
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateMedEvalsNoChildren80067() {
        final String CONC_CODE = AspenConstants.STR_80067_CODE;
        final String THIS_CMSNEXT_NUM = CMSNEXT_NUM_80067_NO_MEDEVAL;

        CMPL123CME__Complaint__c ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        Assert.isTrue(ticket.CMPL123CME__Questionnaires__r.isEmpty(),
            ERROR_SETUP + 'The Ticket needs NO MedEvals to test this function');
        Assert.areEqual(1, ticket.CMPL123CME__Investigations__r.size(),
            ERROR_SETUP + 'The Ticket needs exactly one ProdEval to test this function');
        Assert.areEqual(AspenConstants.STR_80067_Deficiency_Malfunction,
            ticket.CMPL123CME__Investigations__r[0].Conclusion_Disposition__c,
            ERROR_SETUP + 'The ProdEval needs Conclusion Disposition code ' + CONC_CODE);

        // Gather ProdEval Ids to call the function we are testing
        Map<Id, Id> prodEvalIdToTicketId = new Map<Id, Id>();
        for (CMPL123CME__Investigation__c prodEval : ticket.CMPL123CME__Investigations__r) {
            prodEvalIdToTicketId.put(prodEval.Id, ticket.Id);
        }

        Test.startTest();
        ADDInvestigationHandler.updateMedEvals(prodEvalIdToTicketId);
        Test.stopTest();

        // Verify field assignments for MedEvals
        ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        Assert.areEqual(1, ticket.CMPL123CME__Questionnaires__r.size(),
            ERROR_POS + 'A MedEval should have been created');
        CMPL123CME__Questionnaire__c medEval = ticket.CMPL123CME__Questionnaires__r[0];
        Assert.areEqual(AspenConstants.STR_Deficiency, medEval.CMPL123CME__Key_value__c,
            ERROR_POS + 'Wrong KeyValue for the new MedEval');
        Assert.areEqual(AspenConstants.STR_Deficiency, medEval.Conclusion_Disposition_Flag__c,
            ERROR_POS + 'Wrong Conclusion Disposition Flag for the new MedEval');
    }

    /**
     * Pos tests for updateMedEvals where Tickets w/code 80064 have only VOID MedEval children
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateMedEvalsVoidChildren80064() {
        final String CONC_CODE = AspenConstants.STR_80064_CODE;
        final String THIS_CMSNEXT_NUM = CMSNEXT_NUM_80064_VOID_MEDEVAL;

        CMPL123CME__Complaint__c ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        Assert.isFalse(ticket.CMPL123CME__Questionnaires__r.isEmpty(),
            ERROR_SETUP + 'The Ticket needs MedEval(s) to test this function');
        for (CMPL123CME__Questionnaire__c medEval : ticket.CMPL123CME__Questionnaires__r) {
            Assert.areEqual(AspenConstants.STR_WF_Closed_Voided, medEval.CMPL123_WF_Status__c,
                ERROR_SETUP + 'All MedEvals must be Closed-Voided for this test');
        }
        Assert.areEqual(1, ticket.CMPL123CME__Investigations__r.size(),
            ERROR_SETUP + 'The Ticket needs exactly one ProdEval to test this function');
        Assert.areEqual(AspenConstants.STR_80064_NO_Deficiency_Malfunction,
            ticket.CMPL123CME__Investigations__r[0].Conclusion_Disposition__c,
            ERROR_SETUP + 'The ProdEval needs Conclusion Disposition code ' + CONC_CODE);

        // Gather ProdEval Ids to call the function we are testing
        Map<Id, Id> prodEvalIdToTicketId = new Map<Id, Id>();
        for (CMPL123CME__Investigation__c prodEval : ticket.CMPL123CME__Investigations__r) {
            prodEvalIdToTicketId.put(prodEval.Id, ticket.Id);
        }

        Integer numMedEvalsBefore = ticket.CMPL123CME__Questionnaires__r.size();
        Test.startTest();
        ADDInvestigationHandler.updateMedEvals(prodEvalIdToTicketId);
        Test.stopTest();

        ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        Integer numMedEvalsAfter = ticket.CMPL123CME__Questionnaires__r.size();
        Assert.areEqual(1, numMedEvalsAfter - numMedEvalsBefore,
            ERROR_POS + 'One MedEval should have been created');
        for (CMPL123CME__Questionnaire__c medEval : ticket.CMPL123CME__Questionnaires__r) {
            if (medEval.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Voided) {
                // Ignore this MedEval. We inserted a new MedEval, but left this one untouched
                continue;
            }

            Assert.areEqual(AspenConstants.POTENTIAL_REPORTABLE_EVENT, medEval.CMPL123CME__Key_value__c,
                ERROR_POS + 'Wrong KeyValue for the new MedEval');
            Assert.areEqual(AspenConstants.STR_Malfunction_Requiring_Med_Eval,
                medEval.Conclusion_Disposition_Flag__c,
                ERROR_POS + 'Wrong Conclusion Disposition Flag for the new MedEval');
        }
    }

    /**
     * Pos tests for updateMedEvals where Tickets w/code 80067 have only VOID MedEval children
     * @author R3.1, Larry Resnik
     */
    @isTest
    static void testUpdateMedEvalsVoidChildren80067() {
        final String CONC_CODE = AspenConstants.STR_80067_CODE;
        final String THIS_CMSNEXT_NUM = CMSNEXT_NUM_80067_VOID_MEDEVAL;

        CMPL123CME__Complaint__c ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        Assert.isFalse(ticket.CMPL123CME__Questionnaires__r.isEmpty(),
            ERROR_SETUP + 'The Ticket needs MedEval(s) to test this function');
        for (CMPL123CME__Questionnaire__c medEval : ticket.CMPL123CME__Questionnaires__r) {
            Assert.areEqual(AspenConstants.STR_WF_Closed_Voided, medEval.CMPL123_WF_Status__c,
                ERROR_SETUP + 'All MedEvals must be Closed-Voided for this test');
        }
        Assert.areEqual(1, ticket.CMPL123CME__Investigations__r.size(),
            ERROR_SETUP + 'The Ticket needs exactly one ProdEval to test this function');
        Assert.areEqual(AspenConstants.STR_80067_Deficiency_Malfunction,
            ticket.CMPL123CME__Investigations__r[0].Conclusion_Disposition__c,
            ERROR_SETUP + 'The ProdEval needs Conclusion Disposition code ' + CONC_CODE);

        // Gather ProdEval Ids to call the function we are testing
        Map<Id, Id> prodEvalIdToTicketId = new Map<Id, Id>();
        for (CMPL123CME__Investigation__c prodEval : ticket.CMPL123CME__Investigations__r) {
            prodEvalIdToTicketId.put(prodEval.Id, ticket.Id);
        }

        Integer numMedEvalsBefore = ticket.CMPL123CME__Questionnaires__r.size();
        Test.startTest();
        ADDInvestigationHandler.updateMedEvals(prodEvalIdToTicketId);
        Test.stopTest();

        // Verify field assignments for MedEvals
        ticket = queryForTicketAndChildren(THIS_CMSNEXT_NUM);
        Integer numMedEvalsAfter = ticket.CMPL123CME__Questionnaires__r.size();
        Assert.areEqual(1, numMedEvalsAfter - numMedEvalsBefore,
            ERROR_POS + 'One MedEval should have been created');
        for (CMPL123CME__Questionnaire__c medEval : ticket.CMPL123CME__Questionnaires__r) {
            if (medEval.CMPL123_WF_Status__c == AspenConstants.STR_WF_Closed_Voided) {
                // Ignore this MedEval. We inserted a new MedEval, but left this one untouched
                continue;
            }

            Assert.areEqual(AspenConstants.STR_Deficiency, medEval.CMPL123CME__Key_value__c,
                ERROR_POS + 'Wrong KeyValue for the new MedEval');
            Assert.areEqual(AspenConstants.STR_Deficiency, medEval.Conclusion_Disposition_Flag__c,
                ERROR_POS + 'Wrong Conclusion Disposition Flag for the new MedEval');
        }
    }
}