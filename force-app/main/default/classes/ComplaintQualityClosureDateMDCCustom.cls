/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
 * @What  : ComplaintQualityClosureDateMDCCustom.
 * @Why   : Global class to check if an MDC should be made for Ticket's Complaint Quality Closure Date.
 * @When  : 20-NOV-2018
 * @Where : From TicketCQCDMDCCustom Class
 *  -------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer             Date                   Modification ID                 Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                 20-NOV-2018            Work ID / Case ID               Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                 20-AUG-2020            Code Audit                      Updated class comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik          05-JUN-2023            CHaRM R3.1, IPDR 299            Now handles ProdEvals with code 80064.
 * Moved most logic out of TicketCQCDMDCCustom so that processing is localized to this class.
 * Reworded @Why to add clarity.
 * --------------------------------------------------------------------------------------------------------------------------------------
 **/
public class ComplaintQualityClosureDateMDCCustom {
    @testVisible private static final Set<String> PRODEVAL_CODES = new Set<String>{
        AspenConstants.STR_80067_Deficiency_Malfunction,
        AspenConstants.STR_80064_NO_Deficiency_Malfunction
    };
    // R3.1, Larry: Replaced public variables with getter-only accessors that
    // relate directly to the numbered from the MDC Logic document.
    public static Boolean isMeetingCaseOne{get; private set;}
    public static Boolean isMeetingCaseTwo{get; private set;}
    public static Boolean isMeetingCaseThree{get; private set;}
    public static Boolean isMeetingCaseFour{get; private set;}
    public static Boolean isMeetingAnyCase{
        get{
            return isMeetingCaseOne || isMeetingCaseTwo ||
                isMeetingCaseThree || isMeetingCaseFour;
        }
    }

    /**
     * @Method       : setDefaults
     * @Invoke       : Events from TicketCQCDMDCCustom.class
     * @Description  : set Defaults for Record Id
     * @Return       : N/A
     * @Params       : Id recordId
     * @Revision     : R3.1, Larry: Now makes an MDC for code 80064.
     * Public variables were changed so that logic is contained in this class
     * instead of handed off to TicketCQCDMDCCustom for further processing.
     **/
    public static void setDefaults(Id recordId) {
        isMeetingCaseOne = isMeetingCaseTwo = isMeetingCaseThree = isMeetingCaseFour = false;

        if (recordId == null) {
            return;
        }

        // R3.1, Larry: Now gets ProdEvals with code 80064 as well.
        // Note: A Closed-Done MedEval implies the ProdEval was closed with code 80064 or 80067 (malfunction).
        CMPL123CME__Complaint__c ticketWithChilds = [
            SELECT Id, Overall_Reportable_Status__c, Complaint_Quality_Closure_Date__c,
            (
                SELECT Id, CMPL123_WF_Status__c, Reportability__c
                FROM CMPL123CME__Questionnaires__r
                WHERE Reportability__c = :AspenConstants.REPORTABILITY_YES AND
                CMPL123_WF_Status__c != :AspenConstants.STR_WF_Closed_Voided
                LIMIT 1
            ), (
                SELECT Id, CMPL123_WF_Status__c, Conclusion_Disposition__c
                FROM CMPL123CME__Investigations__r
                WHERE CMPL123_WF_Status__c = :AspenConstants.STR_WF_Closed_Done AND
                Conclusion_Disposition__c IN :PRODEVAL_CODES
                LIMIT 1
            )
            FROM CMPL123CME__Complaint__c
            WHERE Id = :recordId
        ];

        // R3.1, Larry: Changed to local variable so that logic is contained in this function.
        Boolean hasProdEval = !ticketWithChilds.CMPL123CME__Investigations__r.isEmpty();
        Boolean hasNoMedEvalsOrAllAreVoided = ticketWithChilds.CMPL123CME__Questionnaires__r.isEmpty();
        Boolean isMedEvalNotReportable = !hasNoMedEvalsOrAllAreVoided;
        Boolean isTicketOverallReportableMine =
            ticketWithChilds.Overall_Reportable_Status__c == AspenConstants.STR_Reportable;
        isMeetingCaseOne = isTicketOverallReportableMine;

        if (!hasProdEval) {
            // There is at least one non-closed ProdEval, so only case #1 matters
            return;
        }

        CMPL123CME__Investigation__c prodEval = ticketWithChilds.CMPL123CME__Investigations__r[0];
        isMeetingCaseTwo = hasNoMedEvalsOrAllAreVoided &&
            prodEval.Conclusion_Disposition__c == AspenConstants.STR_80067_Deficiency_Malfunction;
        isMeetingCaseThree = hasNoMedEvalsOrAllAreVoided &&
            prodEval.Conclusion_Disposition__c == AspenConstants.STR_80064_NO_Deficiency_Malfunction;
        isMeetingCaseFour = isMedEvalNotReportable &&
            prodEval.Conclusion_Disposition__c == AspenConstants.STR_80067_Deficiency_Malfunction;
    }
}