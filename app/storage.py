import random
import string

#initialize in-memory store (testing)
_store: dict[str,str]={}

def _generate_code() -> str:
    return "".join(random.choices(string.ascii_letters+string.digits,k-=6))

def save_url(long_url: str) -> str:
    """
    generates a new code for input url and stores in dict
    """
    code = _generate_code()
    while code in _store:
        code=_generate_code()
    _store[code] = long_url
    return code

def get_url(code: str) -> str | None:
    """
    gets the original url from shortened code
    """
    return _store.get(code)