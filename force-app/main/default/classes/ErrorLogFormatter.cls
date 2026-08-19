/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : ErrorLogFormatter.
* @Why   : Utility class to handle all logic related to formatting Error Log before its insert.
* @When  : 09-AUG-2019.
* @Where : From BatchTicketAutoPromote, SendAttachmentToTIBCOService, TicketServiceHandler class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                      Modification ID              Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    09-AUG-2019               Work ID / Case ID            Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    03-AUG-2020               Code Audit                   Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ErrorLogFormatter {

    private static final Integer maxCMSNextTicketNumberSize = SObjectType.Error_Log__c.Fields.CMSNext_Ticket_Number__c.Length;
    private static final Integer maxErrorTypeSize = SObjectType.Error_Log__c.Fields.Error_Type__c.Length;
    private static final Integer maxErrorTextSize = SObjectType.Error_Log__c.Fields.Error_Text__c.Length;
    private static final Integer maxPayloadDataSize = SObjectType.Error_Log__c.Fields.Payload_Data__c.Length;

    /*
    * @Method       : GetFormattedError.
    * @Description  : Formats the error.
    * @Invoke       : From BatchTicketAutoPromote, SendAttachmentToTIBCOService and TicketServiceHandler.
    * @Return       : Error_Log__c object.
    * @Params       : String cmsNextTicketNumber, String errorType, String errorText, String payloadData.
    */
    public static Error_Log__c GetFormattedError(String cmsNextTicketNumber, String errorType, String errorText, String payloadData) {
        Error_Log__c formattedError = new Error_Log__c();
        formattedError.CMSNext_Ticket_Number__c = ErrorLogFormatter.CutLogItemValueIfNeeded(cmsNextTicketNumber, maxCMSNextTicketNumberSize);
        formattedError.Error_Type__c = ErrorLogFormatter.CutLogItemValueIfNeeded(errorType, maxErrorTypeSize);
        formattedError.Error_Text__c = ErrorLogFormatter.PrettifyErrorText(ErrorLogFormatter.CutLogItemValueIfNeeded(errorText, maxErrorTextSize));
        formattedError.Payload_Data__c = ErrorLogFormatter.CutLogItemValueIfNeeded(payloadData, maxPayloadDataSize);
        return formattedError;
    }

    /*
    * @Method       : CutLogItemValueIfNeeded.
    * @Description  : Cuts valToCheckAndCutIfNeeded passув parameter basing on maxStringSize.
    * @Invoke       : From GetFormattedError method.
    * @Return       : Cutted valToCheckAndCutIfNeeded parameter.
    * @Params       : String valToCheckAndCutIfNeeded, Integer maxStringSize.
    */
    private static String CutLogItemValueIfNeeded (String valToCheckAndCutIfNeeded, Integer maxStringSize) {
        if (valToCheckAndCutIfNeeded != null) {
            if (valToCheckAndCutIfNeeded.length() > maxStringSize) {
                valToCheckAndCutIfNeeded = valToCheckAndCutIfNeeded.substring(0, maxStringSize);
            }
        }
        return valToCheckAndCutIfNeeded;
    }

    /*
    * @Method       : PrettifyErrorText.
    * @Description  : Formats error text according to regex.
    * @Invoke       : From GetFormattedError method.
    * @Return       : Formatted errorTextToPrettify parameter.
    * @Params       : String errorTextToPrettify.
    */
    private static String PrettifyErrorText (String errorTextToPrettify) {
        String prettifiedText;
        if (errorTextToPrettify != null) {
            errorTextToPrettify = ErrorLogFormatter.NormalizeTextToPrettify(errorTextToPrettify);
            Pattern pat = Pattern.compile('(?<=":")((?!errorType|errorTxn|errorMessage).)+(?=",")');
            Matcher mat = pat.matcher(errorTextToPrettify);
            prettifiedText = '';
            while (mat.find()) {
                prettifiedText += errorTextToPrettify.substring(mat.start(), mat.end()) + '. ';
            }
            prettifiedText = prettifiedText.removeEnd(' ');
            if (String.isEmpty(prettifiedText)) {
                prettifiedText = errorTextToPrettify;
            }
        }
        return prettifiedText;
    }

    /*
    * @Method       : NormalizeTextToPrettify.
    * @Description  : Removes line breaks and cariage returns from textToNormalize parameter.
    * @Invoke       : From PrettifyErrorText method.
    * @Return       : Formatted textToNormalize parameter.
    * @Params       : String textToNormalize.
    */
    private static String NormalizeTextToPrettify (String textToNormalize) {
        String normalizedText;
        if (textToNormalize != null) {
            normalizedText = textToNormalize.replace('\\n', ' ');
            normalizedText = normalizedText.replace('\\r', ' ');
            normalizedText = normalizedText.normalizeSpace();
        }
        return normalizedText;
    }

}