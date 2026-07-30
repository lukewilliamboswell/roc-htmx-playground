# Product documents

Product documents use a numeric filename prefix to preserve their reading
order in a plain directory listing:

- `00`–`09` are enduring product contracts and their examples.
- `10` onward are delivery slices in implementation order.

## Enduring designs

These documents describe the intended minimal product and its stable data
contracts. Delivery slices refer back to them; implementing a slice does not
replace or narrow them.

- [`00-full-design-minimal-crm.md`](00-full-design-minimal-crm.md) defines the
  complete minimal CRM requirements, workflows, business rules, and product
  decisions.
- [`01-full-design-json-interchange.md`](01-full-design-json-interchange.md)
  defines the complete-workspace JSON import and export contract.
- [`02-example-json-interchange.json`](02-example-json-interchange.json) is the
  corresponding example interchange file.

## Delivery slices

`NN-slice-*` documents define the acceptance boundary for one implementation
slice.

1. [`10-slice-company-enquiry.md`](10-slice-company-enquiry.md) — capture and
   maintain people, companies, and accountable follow-up.
2. [`11-slice-opportunity-qualification.md`](11-slice-opportunity-qualification.md)
   — qualify an existing relationship into an open deal and make it visible in
   the pipeline.
