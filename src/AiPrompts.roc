import "../prompts/business-card/system.txt" as business_card_system : Str
import "../prompts/business-card/user.txt" as business_card_user : Str
import "../prompts/business-card/output-schema.json" as business_card_schema : Str

AiPrompts := [].{
	Bundle := {
		featureId : Str,
		promptId : Str,
		system : Str,
		user : Str,
		schema : Str,
	}

	business_card : Bundle
	business_card = {
		featureId: "business_card_scanner",
		promptId: "business_card",
		system: business_card_system.trim(),
		user: business_card_user.trim(),
		schema: business_card_schema.trim(),
	}
}

expect !AiPrompts.business_card.system.is_empty()
expect !AiPrompts.business_card.user.is_empty()
expect AiPrompts.business_card.schema.contains("\"additionalProperties\": false")
expect AiPrompts.business_card.system.contains("untrusted data")
