/*
* @why  : To Test all scenarios on the class CustomerResponseCustExpectMDCCustom
* @when : CreatedDate : 12-OCT-2018  ModifiedDate : 14-JAN-2021
* @what : CustomerResponseCustExpectMDCCustomTest Test Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID       Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit            Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oober                    10-June-2020           N/A                   Updated code part, which is related to Users' insertion.
                                                                          This change designed to prevent a 'DUPLICATE_USERNAME'
                                                                          error during deployment to Production environment
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit           Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    14-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class TicketCQCDMDCCustomTest {
    /**
    * @Method       : setupData
    * @Description  : Create Test Data
    **/
    @testSetup static void setupData() {
        CMPL123__AuditTrail_Config__c objAuditTrialConfig
            = (CMPL123__AuditTrail_Config__c)TestDataFactory.createSObject(new CMPL123__AuditTrail_Config__c(
                CMPL123__Fields__c = 'Complaint_Quality_Closure_Date__c',
                CMPL123__Is_Active__c = true,
                Name = 'CMPL123CME__Complaint__c'),true);

        //Create MDC_Trigger
        CMPL123__MDC_Trigger__c mdcTrigger
            = (CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(new CMPL123__MDC_Trigger__c(CMPL123__Select_Target_Object__c = 'CMPL123CME__Complaint__c',
                CMPL123__Criteria__c = 'Created or Changed',
                CMPL123__Logic__c = '1',
                CMPL123__Active__c = true,
                CMPL123__Record_Detail_Field__c = 'Registration_Ticket__c'),true);

        //Create MDC_Field_Mapping
        CMPL123__MDC_Field_Mapping__c fieldMapping
            = (CMPL123__MDC_Field_Mapping__c)TestDataFactory.createSObject (new CMPL123__MDC_Field_Mapping__c(CMPL123__Field_Name__c = 'Complaint Quality Closure Date1',
                CMPL123__Index__c = 1,
                CMPL123__Field_API__c = 'Complaint_Quality_Closure_Date__c',
                CMPL123__Condition__c = 'Custom',
                CMPL123__Selected_object__c = 'CMPL123CME__Complaint__c',
                CMPL123__Parent_object__c = mdcTrigger.Id,
                CMPL123__Parameters__c = 'TicketCQCDMDCCustom'),true);

        //Create AcknowledgementMapping
        CMPL123__AcknowledgementMapping__c ackMapping
            = (CMPL123__AcknowledgementMapping__c) TestDataFactory.createSObject(new CMPL123__AcknowledgementMapping__c(CMPL123__SelectObject__c = 'CMPL123CME__Complaint__c',
                CMPL123__AckNumber__c = 1,
                CMPL123__PublicGroupAcknowledgment__c = 'Medical Evaluator',
                CMPL123__MDC_Trigger_Acknowledgment__c = mdcTrigger.Id,
                CMPL123__Index__c = 1),true);

        //Create User
        User u1 = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
            LastName = 'last1',
            Email = 'approver@test.com',
            Username = 'approver@test.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
            CompanyName = 'Abott',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Belongs_to_Text__c = 'Tran10'
        ), true);

        User u2 = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
            LastName = 'last2',
            Email = 'investigator@test.com',
            Username = 'investigator@test.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
            CompanyName = 'Abott',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Belongs_to_Text__c = 'Tran10'
        ), true);

        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();

        //Create Reportable Complaint
        CMPL123CME__Complaint__c ComplaintTicket
            = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(Ticket_Type__c = 'Complaint',
                Customer_Reply_Required__c = true,
                Complaint_Quality_Closure_Date__c=DateTime.Now(),
                Overall_Reportable_Status__c='Reportable',
                CMSNext_Ticket_Number__c = '1170560C1245459',
                //TWD Upgrade BEGIN
                CMSNext_Ticket_ID__c = '1170560C1245459',
                //TWD Upgrade END
                RecordTypeId = compRecTypeId), true);

        //Create Questionnaire
        CMPL123CME__Questionnaire__c objQuestionnaire
            = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                CMPL123CME__Complaint__c = ComplaintTicket.Id,
                Reportability_Rationale__c = 'It is Reportable',
                Reportability_Category__c = 'RCML',
                CMPL123_WF_Status__c = 'Regulatory',
                Reportability__c = 'Reportable'
                ),true);

       //Create Investigation
       CMPL123CME__Investigation__c objInvestigation
        = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(new CMPL123CME__Investigation__c(
            Name = 'Prod Eval',
            CMPL123CME__Complaint__c = ComplaintTicket.Id,
            Assessor__c = u2.Id,
            Approver__c = u1.Id,
            Evaluator_Investigator__c = u2.Id,
            Additional_Action_Taken__c = 'No',
            Conclusion_Summary__c = 'malfunction',
            Product_Evaluation_Type__c = 'Lot to lot variability',
            Conclusion_Disposition__c = '80067 Deficiency, Malfunction',
            CMPL123_WF_Status__c = 'Opened'),true);

        //Create Not Reportable Complaint
        CMPL123CME__Complaint__c ComplaintNotReportableTicket
            = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(Ticket_Type__c = 'Complaint',
                Customer_Reply_Required__c = true,
                Complaint_Quality_Closure_Date__c=DateTime.Now(),
                Overall_Reportable_Status__c='Not Reportable',
                CMSNext_Ticket_Number__c = '1170560C1245458',
                //TWD Upgrade BEGIN
                CMSNext_Ticket_ID__c = '1170560C1245458',
                //TWD Upgrade END
                RecordTypeId = compRecTypeId), true);
    }

    /**
    * @Method       : setDefaultsTest
    * @Description  : Update Compalint Qualiy Closure date in the Complaint and the complaint doesn't have without ProdEval and Med Eval then
                    it will not create the MDC
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    public static void medEvalNotCreateMDCTest() {

        CMPL123CME__Complaint__c complaintNotReportable = [SELECT Id, Ticket_Type__c,Med_Evaluator_Pending_MDCs__c
                                                           FROM CMPL123CME__Complaint__c
                                                           WHERE Ticket_Type__c = 'Complaint'
                                                           AND CMSNext_Ticket_Number__c = '1170560C1245458'];


        complaintNotReportable.Complaint_Quality_Closure_Date__c = DateTime.Now().AddDays(2);

        Test.startTest();
        TestDataFactory.updateSObject(complaintNotReportable);
        Test.stopTest();


        System.assertEquals('Insert', [SELECT CMPL123__Action__c FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: complaintNotReportable.Id AND CMPL123__Action__c = 'Insert'].CMPL123__Action__c);

        System.assertEquals('Update', [SELECT CMPL123__Action__c FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: complaintNotReportable.Id AND CMPL123__Action__c = 'Update'].CMPL123__Action__c);

        system.assertEquals(false,[SELECT Med_Evaluator_Pending_MDCs__c FROM CMPL123CME__Complaint__c WHERE ID =: complaintNotReportable.ID].Med_Evaluator_Pending_MDCs__c);
    }

    /**
    * @Method       : setDefaultsWithProdEvalTest
    * @Description  : Update Compalint Qualiy Closure date in the Complaint and the complaint having ProdEval and Med Eval with required
                    condition then it will set the MDC for MedEval
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    public static void medEvalCreateMDCTest() {
        CMPL123CME__Complaint__c objComplaint = [SELECT Id, Ticket_Type__c,Med_Evaluator_Pending_MDCs__c
                                                 FROM CMPL123CME__Complaint__c
                                                 WHERE Ticket_Type__c = 'Complaint'
                                                 AND CMSNext_Ticket_Number__c = '1170560C1245459'];

        objComplaint.Complaint_Quality_Closure_Date__c = DateTime.Now().AddDays(1);

        // This code is used to set the SOSL query results
        List<ID> fixedSearchResults= new List<ID>();
        fixedSearchResults.add(objComplaint.Id);
        Test.setFixedSearchResults(fixedSearchResults);
        //code end

        Test.startTest();
        TestDataFactory.updateSObject(objComplaint);
        Test.stopTest();

        System.assertEquals('Insert', [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: objComplaint.Id AND CMPL123__Action__c = 'Insert'].CMPL123__Action__c);

        System.assertEquals('Update', [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: objComplaint.Id AND CMPL123__Action__c = 'Update'].CMPL123__Action__c);

        System.assertEquals(true, [SELECT Med_Evaluator_Pending_MDCs__c FROM CMPL123CME__Complaint__c WHERE ID =: objComplaint.ID].Med_Evaluator_Pending_MDCs__c);
    }

    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test () {
        TicketCQCDMDCCustom mdcTrigger = new TicketCQCDMDCCustom();
        CMPL123CME__Complaint__c newRecord = new CMPL123CME__Complaint__c(Complaint_Quality_Closure_Date__c = DateTime.Now());
        CMPL123CME__Complaint__c oldRecord = new CMPL123CME__Complaint__c(Complaint_Quality_Closure_Date__c = DateTime.Now().AddDays(1));
        System.assertEquals(false, mdcTrigger.CustomValidation(oldRecord, newRecord));
    }
}