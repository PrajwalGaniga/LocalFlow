"""
LocalFlow Message Templates
Exact copy specifications for WhatsApp communications.
"""


def template_a_new_lead(location: str, skill: str, description: str, request_id: int) -> str:
    """Template A (New Lead -> provider)"""
    desc = description or "General service requested"
    return (
        f"🔔 New Lead — LocalFlow\n"
        f"A customer in {location} needs a {skill}.\n"
        f"Job: {desc}\n"
        f"Request ID: #{request_id}\n\n"
        f"Reply ACCEPT {request_id} to take this job. First to accept gets it."
    )


def template_b_job_confirmed(
    request_id: int,
    consumer_phone: str,
    location: str,
    description: str,
    rate_min: int,
    rate_max: int,
    consumer_name: str | None = None,
) -> str:
    """Template B (Job Confirmed -> provider)"""
    desc = description or "General service requested"
    rates = f"₹{rate_min}–₹{rate_max}" if rate_min and rate_max else "Standard rates"
    customer_line = f"Customer: {consumer_name} (+91{consumer_phone})" if consumer_name else f"Customer: +91{consumer_phone}"
    return (
        f"✅ Job #{request_id} confirmed — it's yours.\n"
        f"{customer_line}\n"
        f"Location: {location}\n"
        f"Details: {desc}\n"
        f"Agreed rate range: {rates}\n\n"
        f"Please contact the customer directly to coordinate timing."
    )


def template_c_provider_assigned(
    provider_name: str,
    rating: float,
    jobs_completed: int,
    provider_phone: str,
    request_id: int
) -> str:
    """Template C (Provider Assigned -> consumer)"""
    return (
        f"Good news — {provider_name} ({rating}★, {jobs_completed} jobs done) has accepted your request.\n"
        f"Contact: +91{provider_phone}\n"
        f"They'll reach out shortly. Once the job is done, reply: DONE {request_id} <rating 1-5>."
    )


def template_d_already_taken(request_id: int) -> str:
    """Template D (Already Taken -> losing provider)"""
    return (
        f"Job #{request_id} has already been accepted by another provider. "
        f"Thanks for being quick — we'll notify you on the next matching job."
    )


def template_e_completion_thanks(provider_name: str) -> str:
    """Template E (Completion thanks -> consumer)"""
    return f"Thanks for your rating! Glad {provider_name} could help. 🙌"


def template_f_rated_notice(
    request_id: int,
    rating: int,
    new_rating_avg: float,
    jobs_completed: int
) -> str:
    """Template F (Rated notice -> provider)"""
    return (
        f"Job #{request_id} marked complete. Customer rated you {rating}★. "
        f"Your LocalFlow rating is now {new_rating_avg}★ across {jobs_completed} jobs."
    )


def template_g_searching(skill: str, location: str, n: int) -> str:
    """Template G (Searching -> consumer)"""
    return (
        f"Got it — looking for a {skill} near {location}. "
        f"Found {n} nearby, reaching out now. We'll message you the moment someone accepts."
    )


def template_h_no_providers(skill: str, location: str) -> str:
    """Template H (No providers -> consumer)"""
    return f"Sorry, no {skill} is available near {location} right now. We'll keep trying — reply again in a bit."


def template_i_need_more_info() -> str:
    """Template I (Need more info -> consumer)"""
    return 'Please tell me what service you need and your area, e.g. "Electrician, Koramangala".'


def template_j_provider_help() -> str:
    """Template J (Help -> unrecognized provider command)"""
    return (
        "Valid commands:\n"
        "ACCEPT <job id>\n"
        "DECLINE <job id>\n"
        "(Customers, not providers, send DONE <job id> <rating> to close a job.)"
    )
