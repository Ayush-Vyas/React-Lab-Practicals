# Richardson Maturity Model Evaluation

## Student Details

* Practical: Week 4
* Topic: Richardson Maturity Model Evaluation
* Application: Task Management REST API

---

## Evaluation Table

| Level   | Criterion                            | Does the API satisfy it? | Evidence                                                          |
| ------- | ------------------------------------ | ------------------------ | ----------------------------------------------------------------- |
| Level 0 | Single entry point for requests      | Yes                      | Express application exposes API endpoints.                        |
| Level 1 | Resources identified using URIs      | Yes                      | `/tasks` and `/tasks/:id` identify task resources.                |
| Level 2 | Proper HTTP methods and status codes | Yes                      | Uses GET, POST, PUT, DELETE with 200, 201, 404 and 500 responses. |
| Level 3 | HATEOAS support                      | No                       | Hypermedia links are not included in responses.                   |

---

## Current Richardson Maturity Level

**The current API satisfies Level 2.**

Reason:

* Resources are identified using meaningful URIs.
* Correct HTTP verbs are used for CRUD operations.
* Appropriate HTTP status codes are returned for successful and failed requests.

---

## HATEOAS Awareness (Level 3)

To achieve Level 3, each task response could include hypermedia links.

Example:

```json
{
  "id": 1,
  "title": "Learn React",
  "completed": false,
  "_links": {
    "self": "/tasks/1",
    "update": "/tasks/1",
    "delete": "/tasks/1"
  }
}
```

These links help clients discover available actions without prior knowledge of the API structure.

---

## Conclusion

The Task Management API successfully satisfies Richardson Maturity Model **Level 2**. To achieve Level 3, HATEOAS links should be added to every resource response.
