/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : TestUtil.
 * @Why   : To make helper methods for test classes.
 * @When  : 14-JUN-2019.
 * @Where : From test classes.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer              Date                   Modification ID                 Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                  14-JUN-2019            Work ID / Case ID               Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rslob                  10-MAY-2020            N/A                             Updated code part, which is related to Users' insertion.
 *                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME' error
 *                                                                                   during deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik           28-NOV-2022            CHaRM R2.2.1                    Added makeTestUser and made insertTestUser be polymorphic
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik           23-FEB-2023            CHaRM R3.0, TWD upgrade         Added makeMdrProblemCodes
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik           24-MAY-2023            CHaRM R3.1, IPDR 116            Added constant MAX_USERNAME_LEN and applied it to makeTestUser.
 *                                                                               Also added getFakeId(), ERROR_POS, ERROR_NEG, ERROR_SETUP
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@IsTest
public class TestUtil {
    private static Integer counter = 0;
    private static final Integer MAX_USERNAME_LEN = 80;
    public static final String ERROR_POS = 'Positive test error: ';
    public static final String ERROR_NEG = 'Negative test error: ';
    public static final String ERROR_SETUP = 'Setup bug: ';

    /**
     * @Method       : setupMDC.
     * @Description  : To insert data required for MDC.
     * @Invoke       : From test classes.
     * @Return       : N/A.
     * @Params       : Type classForTesting, SObjectType objectToTrack, SObjectField fieldToTrack.
     */
    public static void setupMDC(Type classForTesting, SObjectType objectToTrack, SObjectField fieldToTrack) {
        String sObjectName = objectToTrack.getDescribe().getName();
        String fieldApiName = fieldToTrack.getDescribe().getName();
        String fieldLabel = fieldToTrack.getDescribe().getLabel();
        String classUnderTestName = classForTesting.getName();

        TestDataFactory.createSObject(new CMPL123__AuditTrail_Config__c(
            CMPL123__Fields__c = fieldApiName,
            CMPL123__Is_Active__c = true,
            Name = sObjectName
        ), true);

        CMPL123__MDC_Trigger__c mdcTrigger = (CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(new CMPL123__MDC_Trigger__c(
            CMPL123__Select_Target_Object__c = sObjectName,
            CMPL123__Criteria__c = 'Changed',
            CMPL123__Logic__c = '1',
            CMPL123__Active__c = true,
            Name = 'Patient Information Change'
        ), true);

        TestDataFactory.createSObject(new CMPL123__MDC_Field_Mapping__c(
            CMPL123__Field_Name__c = fieldLabel,
            CMPL123__Index__c = 1,
            CMPL123__Field_API__c = fieldApiName,
            CMPL123__Condition__c = 'Custom',
            CMPL123__Selected_object__c = sObjectName,
            CMPL123__Parent_object__c = mdcTrigger.Id,
            CMPL123__Parameters__c = classUnderTestName
        ), true);

        TestDataFactory.createSObject(new CMPL123__AcknowledgementMapping__c(
            CMPL123__SelectObject__c = sObjectName,
            CMPL123__AckNumber__c = 1,
            CMPL123__PublicGroupAcknowledgment__c = 'Medical Evaluator',
            CMPL123__MDC_Trigger_Acknowledgment__c = mdcTrigger.Id,
            CMPL123__Index__c = 1
        ), true);
    }

    /**
     * @Method       : insertTestUser.
     * @Description  : To insert test user.
     * @Invoke       : From test classes.
     * @Return       : User.
     * @Params       : Id profileId, String email, String username.
     * @Revision     : 28-NOV-2022 Larry: Is now polymorphic
     */
    public static User insertTestUser(Id profileId, String email, String username) {
        String belongsToText = 'PEI3';
        Boolean isAlsoInsert = true;
        return makeTestUser(profileId, email, username, belongsToText, isAlsoInsert);
    }

    /**
     * Factory to make a User.
     * Based on the three-parameter insertTestUser.
     * @Author       : 28-NOV-2022 Larry
     */
    public static User makeTestUser(Id profileId, String email, String username, Boolean isAlsoInsert) {
        String belongsToText = 'PEI3';
        return makeTestUser(profileId, email, username, belongsToText, isAlsoInsert);
    }

    /**
     * @Method       : insertTestUser.
     * @Description  : To insert test user with dynamic Belongs_to_Text__c value.
     * @Invoke       : From test classes.
     * @Return       : User.
     * @Params       : Id profileId, String email, String username, String belongsToText.
     * @Revision     : 28-NOV-2022 Larry: Is now polymorphic
     */
    public static User insertTestUser(Id profileId, String email, String username, String belongsToText) {
        Boolean isAlsoInsert = true;
        return makeTestUser(profileId, email, username, belongsToText, isAlsoInsert);
    }

    /**
     * Factory to make a User.
     * Based on the four-parameter insertTestUser.
     * This method was created so that many Users can be created at once without
     * inserting them individually. For example, see ADDInvestigationHandlerTest
     * @Author       : 28-NOV-2022 Larry
     */
    public static User makeTestUser(Id profileId, String email, String username, String belongsToText, Boolean isAlsoInsert) {
        return (User) TestDataFactory.createSObject(new User(
            Alias = 'standt',
            Email = email,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            //Updated to add unique postfix to each username
            Username = (username + '+' + UserInfo.getOrganizationId() + System.currentTimeMillis()).left(MAX_USERNAME_LEN),
            IsActive = true,
            Belongs_to_Text__c = belongsToText
        ), isAlsoInsert);
    }

    /**
     * Factory to create all MDR Codes for section H6.
     * 
     * The created records are NOT inserted.
     * @return Map of MDR Code's Category to its record. See AspenConstants.MDR_CODE_TYPES
     * @author 23-FEB-2023 Larry Resnik
     */
    public static Map<String, CMPL123CME__Complaint_Code__c> makeMdrProblemCodes() {
        Map<String, CMPL123CME__Complaint_Code__c> cmpCodeNameToRecord =
            new Map<String, CMPL123CME__Complaint_Code__c>();
        for (String codeType : AspenConstants.MDR_CODE_TYPES) {
            String name = String.valueOf(System.currentTimeMillis()).subString(6);
            cmpCodeNameToRecord.put(codeType,
                (CMPL123CME__Complaint_Code__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint_Code__c(
                    CMPL123CME__Type__c = codeType,
                    CMPL123CME__Name__c = name + ' Disorder',
                    Name = name
                ), false)
            );
        }
        return cmpCodeNameToRecord;
    }

    /**
     * Makes a fake Salesforce Id so that you can mock a Trigger context
     * 
     * Usage: Id myId = TestUtil.getFakeId(Customer_Response__c.SObjectType);
     * @author R3.1, Larry Resnik
     */
    public static String getFakeId(Schema.SObjectType sot) {
        String suffix = String.valueOf(counter++).leftPad(12, '0');
        return sot.getDescribe().getKeyPrefix() + suffix;
    }
}