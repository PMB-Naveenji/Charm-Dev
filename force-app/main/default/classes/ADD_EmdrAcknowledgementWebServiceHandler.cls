/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADD_EmdrAcknowledgementWebServiceHandler.
* @Why   : To return the EMDR Id based on the acknowledgement.
* @When  : 20-FEB-2026.
* @Where : From EmdrAcknowledgementWebService Class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID          Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin    			       20-FEB-2017			  Work ID / Case ID        Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit               Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit               Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    27-JUL-2020            Code Audit           Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                    18-AUG-2020            Code Audit               Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    07-SEP-2020            Code Audit               Populated empty catch statement.
* --------------------------------------------------------------------------------------------------------------------------------------
* Capgemini                10-Dec-2020            Capgemini              Replace CMPL123CME__G8_MFR_Report_Number__c from CMPL123CME__G9_MFR_Report_Number__c .
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADD_EmdrAcknowledgementWebServiceHandler {
    // To understand the errors required to be log or not from custom settings
    private static Boolean isLogEnabled;

    /*
    * @Method       : validateEMDR.
    * @Description  : To verify whether the EMDR is available in the database or not.
    * @Invoke       : From EmdrAcknowledgementWebService class.
    * @Return       : String eMDRRelatedId.
    * @Params       : String acknowledgementType, String uniqueIdentifier, Map<String,EMDR_Integration__c> emdrSettingsMap.
    */
    public static String validateEMDR(String acknowledgementType, String uniqueIdentifier, Map<String,EMDR_Integration__c> emdrSettingsMap) {
        String notFound = emdrSettingsMap.size() > 0 && emdrSettingsMap.containsKey('EMDR_Not_Found') ? emdrSettingsMap.get('EMDR_Not_Found').Value__c : 'NOT_FOUND';
        String acknowledgement1 = emdrSettingsMap.size() > 0 && emdrSettingsMap.containsKey('EMDR_Acknowledgement1') ? emdrSettingsMap.get('EMDR_Acknowledgement1').Value__c : 'ACK1';
        String acknowledgement2 = emdrSettingsMap.size() > 0 && emdrSettingsMap.containsKey('EMDR_Acknowledgement2') ? emdrSettingsMap.get('EMDR_Acknowledgement2').Value__c : 'ACK2';
        String acknowledgement3 = emdrSettingsMap.size() > 0 && emdrSettingsMap.containsKey('EMDR_Acknowledgement3') ? emdrSettingsMap.get('EMDR_Acknowledgement3').Value__c : 'ACK3';

        String eMDRRelatedId = notFound;
        String ackTypeLowerCase = acknowledgementType.toLowerCase();

        if (ackTypeLowerCase == acknowledgement1.toLowerCase()) {
            try {
                eMDRRelatedId = findReportNoRelatedEMDRId(uniqueIdentifier,notFound);
            } catch(Exception ex) {
                System.debug(ex.getMessage());
            }
        } else if (ackTypeLowerCase == acknowledgement2.toLowerCase()) {
            try {
                eMDRRelatedId = findMessageIdRelatedEMDRId(uniqueIdentifier,notFound,acknowledgement1);
            } catch(Exception ex) {
                System.debug(ex.getMessage());
            }
        } else if (ackTypeLowerCase == acknowledgement3.toLowerCase()) {
            try {
                eMDRRelatedId = findCoreIdRelatedEMDR(uniqueIdentifier,notFound,acknowledgement2);
            } catch(Exception ex) {
                System.debug(ex.getMessage());
            }
        }

        return eMDRRelatedId;
    }
    
    /*
    * @Method       : findReportNoRelatedEMDRId
    * @Description  : This method executes if the acknowledgementType is 'ACK1' and retrieve  the EMDR Id based on the MFR report number and ACK1
    * @Invoke       : From ADD_EmdrAcknowledgementWebServiceHandler
    * @Return       : String - eMDR Id
    * @Params       : String reportNumber,String notFound
    */ 
    private static String findReportNoRelatedEMDRId(String reportNumber,String notFound){
        String emdrId = notFound;
        if(String.isNotBlank(reportNumber)){
            // List<String> closedWfStatus = new List<String>{'Closed - Complete','Closed - Cancelled'};
            for(CMPL123CME__EMDR__c eMDR : [SELECT Id FROM CMPL123CME__EMDR__c
                                            WHERE CMPL123CME__G8_MFR_Report_Number__c= : reportNumber
                                            AND (NOT CMPL123CME__CMPL123_WF_Status__c LIKE 'Closed%')
                                            //AND CMPL123CME__MDR_Submission__c = 'Submitted' ORDER BY CreatedDate DESC LIMIT 1]){
                                            ORDER BY CreatedDate DESC LIMIT 1]){
                                                emdrId = eMDR.Id;
                                            }
        }
        return emdrId;
    }
    
    /*
    * @Method       : findMessageIdRelatedEMDRId
    * @Description  : This method executes if the acknowledgementType is 'ACK2' and retreive the EMDR Id based on the Message Id and ACK2
    * @Invoke       : From ADD_EmdrAcknowledgementWebServiceHandler, EmdrAcknowledgementWebServiceTest
    * @Return       : String - eMDR Id
    * @Params       : String messageId,String notFound,String acknowledgement1
    */ 
    private static String findMessageIdRelatedEMDRId(String messageId,String notFound,String acknowledgement1){
        String emdrId = notFound;

        if(String.isNotBlank(messageId)){
            for(CMPL123CME__Submission_History__c submissionHistory : [SELECT CMPL123CME__Related_EMDR__c FROM CMPL123CME__Submission_History__c
                                                                       WHERE CMPL123CME__Message_Id__c = : messageId AND CMPL123CME__Stage__c =: acknowledgement1
                                                                       ORDER BY CreatedDate DESC LIMIT 1]){

                                                                           emdrId = submissionHistory.CMPL123CME__Related_EMDR__c;
                                                                       }

            if(emdrId.equalsIgnoreCase(notFound)){
                String newMessageId;

                if(messageId.startsWithIgnoreCase('<')){
                    newMessageId = '&lt;'+ messageId.Substring(1,messageId.length());
                }else{
                    newMessageId = messageId;
                }

                if(messageId.endsWithIgnoreCase('>')){
                    newMessageId = newMessageId.Substring(0,newMessageId.length()-1)+'&gt;';
                }else{
                    newMessageId = messageId;
                }

                for(CMPL123CME__Submission_History__c submissionHistory : [SELECT CMPL123CME__Related_EMDR__c FROM CMPL123CME__Submission_History__c
                                                                           WHERE CMPL123CME__Message_Id__c = : newMessageId AND CMPL123CME__Stage__c =: acknowledgement1
                                                                           ORDER BY CreatedDate DESC LIMIT 1]){

                                                                               emdrId = submissionHistory.CMPL123CME__Related_EMDR__c;
                                                                           }
            }
        }

        return emdrId;
    }
    
    /*
    * @Method       : findCoreIdRelatedEMDR
    * @Description  : This method executes if the acknowledgementType is 'ACK3' and retreive the EMDR Id based on the Core Id and ACK3
    * @Invoke       : From ADD_EmdrAcknowledgementWebServiceHandler, EmdrAcknowledgementWebServiceTest
    * @Return       : String - eMDR Id
    * @Params       : String coreId,String notFound,String acknowledgement2
    */ 
    private static String findCoreIdRelatedEMDR(String coreId,String notFound,String acknowledgement2){
        String emdrId = notFound;
        if(String.isNotBlank(coreId)) {
            for(CMPL123CME__Submission_History__c Ack3Submission : [SELECT CMPL123CME__Related_EMDR__c FROM CMPL123CME__Submission_History__c
                                                                    WHERE CMPL123CME__Core_Id__c = : coreId AND CMPL123CME__Stage__c =: acknowledgement2
                                                                    ORDER BY CreatedDate DESC LIMIT 1]){

                                                                        emdrId = Ack3Submission.CMPL123CME__Related_EMDR__c;
                                                                    }
        }
        return emdrId;
    }
}