/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TranslationEmailHandlerTest.
* @Why   : Test class to handle different scenarios from TranslationEmailHandler class.
* @When  : 18-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                    18-OCT-2018            N/A                           Test class optimization.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    10-JUN-2020            N/A                           Updated code part, which is related to Users' insertion.
*                                                                                 This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                                 deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                    Updated header comments.
* ---------------------------------------------------------------------------------------------------------------------------------------------------
* Juneid                   02-FEB-2021             Fixed Erorr                  Updated Wf step to fix workflow Key Value Erorr 
* ----------------------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class TranslationEmailHandlerTest {
    private static final String attDetJSON = '{"att.id":{"translationTaskId":"translationTaskRecord.id",' +
            '"ticketNumber":"translationTaskRecord.Registration_Ticket_Number__c","standardAttName":' +
            '"ABBOTT CHaRM Dry-Run Issue.txt","standardAttachmentId":"attach.id","relatedParentId":' +
            '"cmpl123cmeInvestigationRecord.id","objectLabel":"Ticket","isSelected":true,"fileSize":3018,' +
            '"fileName":"Test 94","customAttachmentId":"att.id"}}';

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup static void setup() {
        insertTestData();
    }

    /*
    * @Method       : insertTestData.
    * @Description  : To insert setup data asynchronously.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @future
    static void insertTestData() {
        User u = (User) TestDataFactory.createSObject(new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
                LastName = 'last',
                Email = 'test@test.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Belongs_to_Text__c = 'Tran10',
                Username = 'test@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        ), true);

        CMPL123__WF_Status__c statusOpened = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'Opened'), true);
        CMPL123__WF_Status__c statusInProcess = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'In Process'), true);
        CMPL123__WF_Status__c statusTaskSentToVendor = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'Task sent to vendor'), true);
        CMPL123__WF_Status__c statusTranslationPendingReview = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'Translation Pending Review'), true);
        insert new CMPL123__WF_Status__c (Name = 'Closed-Done');

        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c (Name = 'Promote'), true);
        CMPL123__WF_Action__c actionSendToVendor = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c (Name = 'Send to Vendor'), true);
        insert new CMPL123__WF_Action__c (Name = 'Populate Translations');

        CMPL123__WF_Rule__c assessProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'Translation task workflow',
                        CMPL123__Target_Object__c = 'Translation_Task__c(Translation_Task)',
                        CMPL123__Record_Type__c = 'Translation_Task',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true),
                true
        );
        insert new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = statusOpened.Id,
                CMPL123__End_Status__c = statusInProcess.Id,
                CMPL123__Action__c = action.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__WF_Rule__c = assessProdRule.Id,
                CMPL123__Is_Start_Step__c = false //@Juneid 2 feb 2021,Replace is Start step as True to false resolve Key value Error
            
        );
        insert new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = statusInProcess.Id,
                CMPL123__End_Status__c = statusTaskSentToVendor.Id,
                CMPL123__Action__c = actionSendToVendor.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__WF_Rule__c = assessProdRule.Id,
                CMPL123__Is_Start_Step__c = false  //@Juneid 2 feb 2021,Replace is Start step as True to false resolve Key value Error
        );
        insert new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = statusTaskSentToVendor.Id,
                CMPL123__End_Status__c = statusTranslationPendingReview.Id,
                CMPL123__Action__c = actionSendToVendor.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__WF_Rule__c = assessProdRule.Id,
                CMPL123__Is_Start_Step__c = true
        );
        Translation_Vendor__c objTranslationVendor = (Translation_Vendor__c) TestDataFactory.createSObject(
                new Translation_Vendor__c(
                        Name = 'Do Not Use',
                        Division__c = 'ADD',
                        Status__c = 'Active',
                        Vendor_Email__c = 'test@test.com'),
                true
        );
        insert new Country__c(
                Name = 'INDIA',
                Division__c = 'ADD',
                Country_Code__c = 'IND',
                Primary_Vigilance_Contact__c = u.Id,
                Preferred_Translation_Vendor__c = objTranslationVendor.Id,
                Translations_Required_flag__c = true
        );
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaintTicket = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'No',
                        Ticket_Description__c = 'test',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        Ticket_Type__c = 'Complaint',
                        Description_of_Available_Returns__c = 'Returns Test',
                        Country_of_origin__c = 'INDIA',
                        RecordTypeId = complaintRTId,
                        Business_Unit__c = 'IA-CC',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                        Customer_Reply_Required__c = false,
                        Translation_Required_flag__c = true),
                true
        );
        String transTaskRecTypeId = Schema.SObjectType.Translation_Task__c
                .getRecordTypeInfosByName()
                .get('Text Translation')
                .getRecordTypeId();
        Translation_Task__c translationTaskRecord = (Translation_Task__c) TestDataFactory.createSObject(
                new Translation_Task__c(
                        CMPL123_WF_Status__c = 'Opened',
                        Vendor_Name__c = objTranslationVendor.Id,
                        RecordTypeId = transTaskRecTypeId,
                        Urgency__c = 'Urgent',
                        Assignee_Name__c = u.Id,
                        Adhoc_Fields__c = 'Contact Name;Customer Name',
                        Parent_Ticket__c = complaintTicket.Id), true);
        insert new Attachment__c(
                Name = 'TranslationTaskAttachment',
                Translation_Task__c = translationTaskRecord.Id,
                Attachment_Type__c = 'Translation'
        );

        insert new CMPL123CME__Investigation__c(
                Name = 'PRODEVAL0920920R1761979-01',
                CMPL123_WF_Status__c = 'Assess',
                Product_List_Numbers__c = '02k44-01',
                Product_Lot_Numbers__c = '41k42815',
                CMPL123CME__Complaint__c = complaintTicket.Id
        );

        insert new Translation_Log__c(
                Attachment_Details_JSON__c = JSON.serializePretty(attDetJSON),
                Type__c = 'File',
                Translation_Task_Id__c = JSON.serializePretty(new Set<String>{ translationTaskRecord.Id }),
                Translation_Id__c = translationTaskRecord.Id
        );
    }

    /*
    * @Method       : testTranslationEmailHandler1.
    * @Description  : To test improper subject.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testMethod void testTranslationEmailHandler1() {
        CMPL123CME__Complaint__c objComplaintTicket = [
                SELECT Name,Translation_Required_flag__c
                FROM CMPL123CME__Complaint__c
                WHERE Customer_Reply_Required__c = FALSE
                        AND pRE_Status__c = 'No'
                LIMIT 1
        ];
        Translation_Vendor__c objTranslationVendor = [
                SELECT Id
                FROM Translation_Vendor__c
                WHERE Vendor_Email__c = 'test@test.com'
                LIMIT 1
        ];
        Translation_Task__c objTranslationTask = [
                SELECT CMPL123_WF_Status__c
                FROM Translation_Task__c
                WHERE Parent_Ticket__c = :objComplaintTicket.Id
                LIMIT 1
        ];
        CMPL123__WF_Status__c objInProcess = [SELECT Name FROM CMPL123__WF_Status__c WHERE Name = 'In Process'];

        System.assertEquals(2, [
                SELECT COUNT()
                FROM Translation_Item__c
                WHERE Translation_Task__c = :objTranslationTask.Id
        ]);
        Test.startTest();
        Boolean exceptionSpotted = false;
        try {
            new TranslationEmailHandler().parseCSV(',",",",",",",","');
        } catch (TranslationEmailHandler.mailCustomException ex) {
            exceptionSpotted = true;
        }
        System.assert(exceptionSpotted);
        TranslationEmailHandler.stripExtension('Test');
        TranslationEmailHandler.stripExtension('Test.test');
        objTranslationTask.CMPL123_WF_Status__c = objInProcess.Name;
        objTranslationTask.Vendor_Name__c = objTranslationVendor.Id;
        objTranslationTask.Urgency__c = 'Normal';
        objTranslationTask.Task_Comments__c = 'Test Comment';
        update objTranslationTask;

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();

        email.subject = 'Re:test';
        env.fromAddress = 'user@test.com';
        email.toAddresses = new List<String>{
                'test@test.com'
        };
        inAtt.body = Blob.valueOf('test');
        inAtt.fileName = 'my attachment name';
        inAtt.mimeTypeSubType = 'plain/txt';

        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[]{
                inAtt
        };

        TranslationEmailHandler objTranslationEmailHandler = new TranslationEmailHandler();
        Boolean caughtEmailException = false;
        try {
            objTranslationEmailHandler.handleInboundEmail(email, env);
        } catch (System.EmailException ex) {
            caughtEmailException = true;
        }
        System.assert(caughtEmailException);
    }

    /*
    * @Method       : testTranslationEmailHandler2.
    * @Description  : To test TranslationEmailHandler.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testMethod void testTranslationEmailHandler2() {
        CMPL123CME__Complaint__c objComplaintTicket = [
                SELECT Name,Translation_Required_flag__c
                FROM CMPL123CME__Complaint__c
                WHERE Customer_Reply_Required__c = FALSE
                        AND pRE_Status__c = 'No'
                LIMIT 1
        ];
        Translation_Vendor__c objTranslationVendor = [
                SELECT Id
                FROM Translation_Vendor__c
                WHERE Vendor_Email__c = 'test@test.com'
                LIMIT 1
        ];
        Translation_Task__c objTranslationTask = [
                SELECT CMPL123_WF_Status__c
                FROM Translation_Task__c
                WHERE Parent_Ticket__c = :objComplaintTicket.Id
                LIMIT 1
        ];
        CMPL123__WF_Status__c objInProcess = [SELECT Name FROM CMPL123__WF_Status__c WHERE Name = 'In Process'];

        System.assertEquals(2, [
                SELECT COUNT()
                FROM Translation_Item__c
                WHERE Translation_Task__c = :objTranslationTask.Id
        ]);
        Test.startTest();

        objTranslationTask.CMPL123_WF_Status__c = objInProcess.Name;
        objTranslationTask.Vendor_Name__c = objTranslationVendor.Id;
        objTranslationTask.Urgency__c = 'Normal';
        objTranslationTask.Task_Comments__c = 'Test Comment';
        update objTranslationTask;

        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
        Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();


        String delimeter = ',';
        String csvHeader = 'Field Name' + delimeter + 'Ticket Number' + delimeter + 'Native' + delimeter + 'Translated'
                + delimeter + 'Related Id' + delimeter + 'Urgency' + delimeter + 'Country\n';
        String csvBody = '';
        for (Translation_Item__c task : [
                SELECT Id, Name, Field_Name__c, Native__c, Translated__c, Translation_Task__c,
                        Translation_Task__r.Urgency__c,Translation_Task__r.Task_Comments__c,
                        Translation_Task__r.Country_Name__c, Translation_Task__r.Vendor_Name__r.Name,
                        Translation_Task__r.Name, Translation_Task__r.CMPL123_WF_Status__c,
                        Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c,
                        Translation_Task__r.Vendor_Name__r.Vendor_Email__c,Translation_Task__r.Vendor_Name__c
                FROM Translation_Item__c
                WHERE Translation_Task__c = :objTranslationTask.Id
        ]) {
            if (task.Translated__c == null) {
                csvBody += (task.Field_Name__c.contains(',') ? '\"' + task.Field_Name__c + '\"' : task.Field_Name__c)
                        + delimeter + task.Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c + delimeter;
                csvBody += task.Native__c.contains('\n') || task.Native__c.contains(',') ? '\"' + task.Native__c
                        + '\"' + delimeter : task.Native__c + delimeter;
                csvBody += task.Translated__c != null ? task.Translated__c + delimeter + task.Id + delimeter
                        + task.Translation_Task__r.Urgency__c + delimeter + task.Translation_Task__r.Country_Name__c
                        + '\n' : '' + delimeter + task.Id + delimeter + task.Translation_Task__r.Urgency__c + delimeter
                        + task.Translation_Task__r.Country_Name__c + '\n';
            }
        }
        String fileBody = csvHeader + csvBody;

        Translation_Log__c objTranslationLog = (Translation_Log__c) TestDataFactory.createSObject(
                new Translation_Log__c (
                        Attachment_Details_JSON__c = JSON.serializePretty(attDetJSON),
                        Translation_Task_Id__c = JSON.serializePretty(
                                new Set<String>{
                                        objTranslationTask.Id
                                })),
                true
        );

        email.subject = 'Re:Translation Required(' + objTranslationLog.Id + ')';
        env.fromAddress = 'user@test.com';
        email.toAddresses = new List<String>{
                'test@test.com'
        };
        inAtt.body = Blob.valueOf('\uFEFF' + fileBody);
        inAtt.fileName = 'Translation.csv';
        inAtt.mimeTypeSubType = 'text/csv; charset=UTF-8';

        attachmenttext.body = fileBody;
        attachmenttext.fileName = 'Translation.csv';
        attachmenttext.mimeTypeSubType = 'text/csv; charset=UTF-8';
        email.textAttachments = new Messaging.InboundEmail.TextAttachment[]{
                attachmenttext
        };

        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[]{
                inAtt
        };

        TranslationEmailHandler objTranslationEmailHandler = new TranslationEmailHandler();
        objTranslationEmailHandler.handleInboundEmail(email, env);

        List<String> rowDataList = fileBody.trim().split('\n').size() == 1 ?
                fileBody.trim().split('\r') :
                fileBody.trim().split('\n');
        List<String>fieldLabels = rowDataList[0].split(',');
        System.assertEquals(7, fieldLabels.size());
    }

    /*
    * @Method       : testTranslationEmailHandler3.
    * @Description  : To test TranslationEmailHandler.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testMethod void testTranslationEmailHandler3() {
        CMPL123CME__Complaint__c objComplaintTicket = [
                SELECT Name,Translation_Required_flag__c
                FROM CMPL123CME__Complaint__c
                WHERE Customer_Reply_Required__c = FALSE
                        AND pRE_Status__c = 'No'
                LIMIT 1
        ];
        Translation_Vendor__c objTranslationVendor = [
                SELECT Id
                FROM Translation_Vendor__c
                WHERE Vendor_Email__c = 'test@test.com'
                LIMIT 1
        ];
        Translation_Task__c objTranslationTask = [
                SELECT CMPL123_WF_Status__c
                FROM Translation_Task__c
                WHERE Parent_Ticket__c = :objComplaintTicket.Id
                LIMIT 1
        ];
        CMPL123__WF_Status__c objInProcess = [
                SELECT Name
                FROM CMPL123__WF_Status__c
                WHERE Name = 'In Process'
        ];

        System.assertEquals(2, [
                SELECT COUNT()
                FROM Translation_Item__c
                WHERE Translation_Task__c = :objTranslationTask.Id
        ]);
        Test.startTest();

        objTranslationTask.CMPL123_WF_Status__c = objInProcess.Name;
        objTranslationTask.Vendor_Name__c = objTranslationVendor.Id;
        objTranslationTask.Urgency__c = 'Normal';
        objTranslationTask.Task_Comments__c = 'Test Comment';
        update objTranslationTask;

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
        Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();

        String delimeter = ',';
        String csvHeader = 'Field Name' + delimeter + 'Ticket Number' + delimeter + 'Native' + delimeter + 'Translated'
                + delimeter + 'Related Id' + delimeter + 'Urgency' + delimeter + 'Country\n';
        String csvBody = '';
        for (Translation_Item__c task : [
                SELECT Id, Name, Field_Name__c, Native__c, Translated__c, Translation_Task__c,
                        Translation_Task__r.Urgency__c,Translation_Task__r.Task_Comments__c,
                        Translation_Task__r.Country_Name__c, Translation_Task__r.Vendor_Name__r.Name,
                        Translation_Task__r.Name, Translation_Task__r.CMPL123_WF_Status__c,
                        Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c,
                        Translation_Task__r.Vendor_Name__r.Vendor_Email__c,Translation_Task__r.Vendor_Name__c
                FROM Translation_Item__c
                WHERE Translation_Task__c = :objTranslationTask.Id
        ]) {
            if (task.Translated__c == null) {
                csvBody += (task.Field_Name__c.contains(',') ? '\"' + task.Field_Name__c + '\"' : task.Field_Name__c)
                        + delimeter + task.Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c + delimeter;
                csvBody += task.Native__c.contains('\n') || task.Native__c.contains(',') ? '\"' + task.Native__c + '\"'
                        + delimeter : task.Native__c + delimeter;
                csvBody += task.Translated__c != null ? task.Translated__c + delimeter + task.Id + delimeter
                        + task.Translation_Task__r.Urgency__c + delimeter + task.Translation_Task__r.Country_Name__c
                        + '\n' : '' + delimeter + task.Id + delimeter + task.Translation_Task__r.Urgency__c
                        + delimeter + task.Translation_Task__r.Country_Name__c + '\n';
            }
        }
        String fileBody = csvHeader + csvBody;

        Translation_Log__c objTranslationLog = (Translation_Log__c) TestDataFactory.createSObject(
                new Translation_Log__c (
                        Attachment_Details_JSON__c = JSON.serializePretty(attDetJSON),
                        Translation_Task_Id__c = JSON.serializePretty(new Set<String>{
                                objTranslationTask.Id
                        }),
                        Type__c = 'Text'),
                true);

        email.subject = 'Re:Translation Required(' + objTranslationLog.Id + ')';
        env.fromAddress = 'user@test.com';
        email.toAddresses = new List<String>{
                'test@test.com'
        };
        email.ccAddresses = new List<String>{
                'test@test1.com'
        };
        inAtt.body = Blob.valueOf('\uFEFF' + fileBody);
        inAtt.fileName = 'Translation.txt';
        inAtt.mimeTypeSubType = 'text/csv; charset=UTF-8';

        attachmenttext.body = fileBody;
        attachmenttext.fileName = 'Translation.txt';
        attachmenttext.mimeTypeSubType = 'text/csv; charset=UTF-8';
        email.textAttachments = new Messaging.InboundEmail.TextAttachment[]{
                attachmenttext
        };

        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[]{
                inAtt
        };

        Boolean caughtEmailException = false;
        try {
            TranslationEmailHandler objTranslationEmailHandler = new TranslationEmailHandler();
            objTranslationEmailHandler.handleInboundEmail(email, env);
        } catch (System.EmailException e) {
            caughtEmailException = true;
        }
        System.assert(caughtEmailException);
    }

    /*
    * @Method       : testTranslationEmailHandler4.
    * @Description  : To test TranslationEmailHandler.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testMethod void testTranslationEmailHandler4() {
        CMPL123CME__Complaint__c objComplaintTicket = [
                SELECT Name,Translation_Required_flag__c
                FROM CMPL123CME__Complaint__c
                WHERE Customer_Reply_Required__c = FALSE
                        AND pRE_Status__c = 'No'
                LIMIT 1
        ];
        Translation_Vendor__c objTranslationVendor = [
                SELECT Id
                FROM Translation_Vendor__c
                WHERE Vendor_Email__c = 'test@test.com'
                LIMIT 1
        ];
        Translation_Task__c objTranslationTask = [
                SELECT CMPL123_WF_Status__c
                FROM Translation_Task__c
                WHERE Parent_Ticket__c = :objComplaintTicket.Id
                LIMIT 1
        ];
        CMPL123__WF_Status__c objInProcess = [SELECT Id,Name FROM CMPL123__WF_Status__c WHERE Name = 'In Process'];

        System.assertEquals(2, [
                SELECT COUNT()
                FROM Translation_Item__c
                WHERE Translation_Task__c = :objTranslationTask.Id
        ]);
        Test.startTest();

        objTranslationTask.CMPL123_WF_Status__c = objInProcess.Name;
        objTranslationTask.Vendor_Name__c = objTranslationVendor.Id;
        objTranslationTask.Urgency__c = 'Normal';
        objTranslationTask.Task_Comments__c = 'Test Comment';
        update objTranslationTask;

        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
        Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();

        String delimeter = ',';
        String csvHeader = 'Field Name' + delimeter + 'Ticket Number' + delimeter + 'Native' + delimeter + 'Translated'
                + delimeter + 'Related Id' + delimeter + 'Urgency' + delimeter + 'Country\n';
        String csvBody = '';
        for (Translation_Item__c task : [
                SELECT Id, Name, Field_Name__c, Native__c, Translated__c, Translation_Task__c,
                        Translation_Task__r.Urgency__c,Translation_Task__r.Task_Comments__c,
                        Translation_Task__r.Country_Name__c, Translation_Task__r.Vendor_Name__r.Name,
                        Translation_Task__r.Name, Translation_Task__r.CMPL123_WF_Status__c,
                        Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c,
                        Translation_Task__r.Vendor_Name__r.Vendor_Email__c,Translation_Task__r.Vendor_Name__c
                FROM Translation_Item__c
                WHERE Translation_Task__c = :objTranslationTask.Id
        ]) {
            if (task.Translated__c == null) {
                csvBody += (task.Field_Name__c.contains(',') ? '\"' + task.Field_Name__c + '\"' : task.Field_Name__c)
                        + delimeter + task.Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c + delimeter;
                csvBody += task.Native__c.contains('\n') || task.Native__c.contains(',') ? '\"' + task.Native__c
                        + '\"' + delimeter : task.Native__c + delimeter;
                csvBody += task.Translated__c != null ? task.Translated__c + delimeter + task.Id + delimeter
                        + task.Translation_Task__r.Urgency__c + delimeter + task.Translation_Task__r.Country_Name__c
                        + '\n' : '' + delimeter + task.Id + delimeter + task.Translation_Task__r.Urgency__c + delimeter
                        + task.Translation_Task__r.Country_Name__c + '\n';
            }
        }
        String fileBody = csvHeader + csvBody;
		
        Translation_Log__c objTranslationLog = (Translation_Log__c) TestDataFactory.createSObject(
                new Translation_Log__c (
                        Attachment_Details_JSON__c = attDetJSON,//Removed JSON.serializePretty by Syed on 6th Sep 2022
                        Translation_Task_Id__c = JSON.serializePretty(
                                new Set<String>{
                                        objTranslationTask.Id
                                }),
                        Type__c = 'File'),
                true);

        email.subject = 'Re:Translation Required(' + objTranslationLog.Id + ')';
        env.fromAddress = 'user@test.com';
        email.ccAddresses =new List<String>{
                'cctest@test.com'
        };
        email.toAddresses = new List<String>{
                'test@test.com'
        };
        inAtt.body = Blob.valueOf('\uFEFF' + fileBody);
        inAtt.fileName = 'Translation.txt';
        inAtt.mimeTypeSubType = 'text/csv; charset=UTF-8';

        attachmenttext.body = fileBody;
        attachmenttext.fileName = 'Translation.txt';
        attachmenttext.mimeTypeSubType = 'text/csv; charset=UTF-8';
        email.textAttachments = new Messaging.InboundEmail.TextAttachment[]{
                attachmenttext
        };

        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[]{
                inAtt
        };

        TranslationEmailHandler objTranslationEmailHandler = new TranslationEmailHandler();
        //Added by Syed on 6th Sep 2022
        try{
            objTranslationEmailHandler.handleInboundEmail(email, env);
        }catch(Exception ex){
            system.assertEquals('SendEmail failed. First exception on row 0; first error: INVALID_EMAIL_ADDRESS, Email address is invalid: null: [ccAddresses, null]', ex.getMessage());
        }

    }

    /*
    * @Method       : testTranslationEmailHandler5.
    * @Description  : To test TranslationEmailHandler.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testMethod void testTranslationEmailHandler5() {
        CMPL123CME__Complaint__c objComplaintTicket = [
                SELECT Name,Translation_Required_flag__c
                FROM CMPL123CME__Complaint__c
                WHERE Customer_Reply_Required__c = FALSE
                        AND pRE_Status__c = 'No'
                LIMIT 1
        ];
        Translation_Vendor__c objTranslationVendor = [
                SELECT Id
                FROM Translation_Vendor__c
                WHERE Vendor_Email__c = 'test@test.com'
                LIMIT 1
        ];
        Translation_Task__c objTranslationTask = [
                SELECT Id,CMPL123_WF_Status__c
                FROM Translation_Task__c
                WHERE Parent_Ticket__c = :objComplaintTicket.Id
                LIMIT 1
        ];
        CMPL123__WF_Status__c objInProcess = [SELECT Id,Name FROM CMPL123__WF_Status__c WHERE Name = 'In Process'];

        System.assertEquals(2, [
                SELECT COUNT()
                FROM Translation_Item__c
                WHERE Translation_Task__c = :objTranslationTask.Id
        ]);
        Test.startTest();

        objTranslationTask.CMPL123_WF_Status__c = objInProcess.Name;
        objTranslationTask.Vendor_Name__c = objTranslationVendor.Id;
        objTranslationTask.Urgency__c = 'Normal';
        objTranslationTask.Task_Comments__c = 'Test Comment';
        update objTranslationTask;

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String delimeter = ',';
        String csvBody = '';
        for (Translation_Item__c task : [
                SELECT Id, Name, Field_Name__c, Native__c, Translated__c, Translation_Task__c,
                        Translation_Task__r.Urgency__c,Translation_Task__r.Task_Comments__c,
                        Translation_Task__r.Country_Name__c, Translation_Task__r.Vendor_Name__r.Name,
                        Translation_Task__r.Name, Translation_Task__r.CMPL123_WF_Status__c,
                        Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c,
                        Translation_Task__r.Vendor_Name__r.Vendor_Email__c,Translation_Task__r.Vendor_Name__c
                FROM Translation_Item__c
                WHERE Translation_Task__c = :objTranslationTask.Id
        ]) {
            if (task.Translated__c == null) {
                csvBody += (task.Field_Name__c.contains(',') ? '\"' + task.Field_Name__c + '\"' : task.Field_Name__c) + delimeter + task.Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c + delimeter;
                csvBody += task.Native__c.contains('\n') || task.Native__c.contains(',') ? '\"' + task.Native__c + '\"' + delimeter : task.Native__c + delimeter;
                csvBody += task.Translated__c != null ? task.Translated__c + delimeter + task.Id + delimeter + task.Translation_Task__r.Urgency__c + delimeter + task.Translation_Task__r.Country_Name__c + '\n' : '' + delimeter + task.Id + delimeter + task.Translation_Task__r.Urgency__c + delimeter + task.Translation_Task__r.Country_Name__c + '\n';
            }
        }

        Translation_Log__c objTranslationLog = (Translation_Log__c) TestDataFactory.createSObject(
                new Translation_Log__c (
                        Attachment_Details_JSON__c = JSON.serializePretty(attDetJSON),
                        Translation_Task_Id__c = JSON.serializePretty(
                                new Set<String>{
                                        objTranslationTask.Id
                                })),
                true);

        email.subject = 'Re:Translation Required(' + objTranslationLog.Id + ')';
        env.fromAddress = 'user@test.com';
        email.toAddresses = new List<String>{
                'test@test.com'
        };
        email.plainTextBody = 'received';

        TranslationEmailHandler objTranslationEmailHandler = new TranslationEmailHandler();
        objTranslationEmailHandler.handleInboundEmail(email, env);

    }

    /*
    * @Method       : testTranslationEmailHandler6.
    * @Description  : To test TranslationEmailHandler.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testMethod void testTranslationEmailHandler6() {
        CMPL123CME__Complaint__c objComplaintTicket = [
                SELECT Name,Translation_Required_flag__c
                FROM CMPL123CME__Complaint__c
                WHERE Customer_Reply_Required__c = FALSE
                        AND pRE_Status__c = 'No'
                LIMIT 1
        ];
        Translation_Vendor__c objTranslationVendor = [
                SELECT Id
                FROM Translation_Vendor__c
                WHERE Vendor_Email__c = 'test@test.com'
                LIMIT 1
        ];
        Translation_Task__c objTranslationTask = [
                SELECT CMPL123_WF_Status__c
                FROM Translation_Task__c
                WHERE Parent_Ticket__c = :objComplaintTicket.Id
                LIMIT 1
        ];
        CMPL123__WF_Status__c objInProcess = [SELECT Id,Name FROM CMPL123__WF_Status__c WHERE Name = 'In Process'];
        System.assertEquals(2, [
                SELECT COUNT()
                FROM Translation_Item__c
                WHERE Translation_Task__c = :objTranslationTask.Id
        ]);
        Test.startTest();

        objTranslationTask.CMPL123_WF_Status__c = objInProcess.Name;
        objTranslationTask.Vendor_Name__c = objTranslationVendor.Id;
        objTranslationTask.Urgency__c = 'Normal';
        objTranslationTask.Task_Comments__c = 'Test Comment';
        update objTranslationTask;

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        insert new Translation_Log__c (
                Attachment_Details_JSON__c = JSON.serializePretty(attDetJSON),
                Translation_Task_Id__c = JSON.serializePretty(new Set<String>{
                        objTranslationTask.Id
                })
        );

        email.subject = 'Re:Translation Required(notrecord)';
        env.fromAddress = 'user@test.com';
        email.toAddresses = new List<String>{
                'test@test.com'
        };

        Boolean caughtEmailException = false;
        try {
            // call the class and test it with the data in the testMethod
            TranslationEmailHandler objTranslationEmailHandler = new TranslationEmailHandler();
            objTranslationEmailHandler.handleInboundEmail(email, env);
        } catch (System.EmailException ex) {
            caughtEmailException = true;
        }
        System.assert(caughtEmailException);
    }
}