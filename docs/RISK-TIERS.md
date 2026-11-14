# Risk tiers

## Questions

1. Does it process personal information? Special personal information (health, religion, race, etc.)?
2. Does its output reach someone **outside** the company?
3. Does it make or recommend a **decision about a person** or about money?
4. If it's wrong, is the harm **reversible**?
5. Does a human see every output before it has an effect?

## Tiers

| Tier | Rule of thumb | Examples |
|---|---|---|
| **High** | Decisions or recommendations about people or money, or special personal information | CV screening, credit checks, payment approval |
| **Medium** | Output reaches people outside the company, reversible, not a decision about them | Customer replies, supplier emails |
| **Low** | Internal, reversible, a human reviews every output anyway | Content drafts, internal summaries |

## Required controls

- **Every tier:** C01, C02, C03, C05, C06, C14, C15, C16
- **Medium adds:** C04, C07, C08, C09, C10, C11, C12 (draft, don't send), C13
- **High:** as medium, but stricter. C12 = **a person makes the decision**; C11 includes **paired bias tests**; C13 includes **redaction of protected attributes** and a **retention limit**

If your answers point to a different tier than you expected, trust the answers and write down why.