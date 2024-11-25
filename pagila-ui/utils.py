from dataclasses import dataclass
from typing import Mapping, NamedTuple

from flask import url_for


@dataclass
class Page:
    """Class for creating page links in an html template"""

    page_index: int
    is_current: bool
    url: str = None

    @property
    def page(self) -> int:
        """The number of the page. Starts at 1."""
        return self.page_index + 1


class UrlForParams(NamedTuple):
    endpoint: str
    args: list[any] = []
    kwargs: Mapping[str, any] = dict()


@dataclass
class Pagination:
    """Class for creating pagination in an html template.

    Is required by the pagination macro.
    """

    total_count: int
    # params to construct the URL for a given page.
    url_for_params: UrlForParams
    page_param: str = "p"
    per_page: int = 25
    offset: int = 0

    @property
    def page_count(self) -> int:
        """The total number of pages."""
        return self.total_count // self.per_page + 1

    @property
    def current_page_index(self) -> int:
        """The zero based index of the current page."""
        return self.offset // self.per_page

    @property
    def base_url(self) -> str:
        return self._create_url()

    def _create_url(self, page=None) -> str:
        params = self.url_for_params
        params.kwargs[self.page_param] = page
        return url_for(params.endpoint, *params.args, **params.kwargs)

    def get_rel(self, page_offset) -> Page:
        """Get the page that is page_offset after the current one."""
        page_index = self.current_page_index + page_offset
        if page_index < 0 or page_index >= self.page_count:
            return None
        return self.get_abs(page_index)

    def get_abs(self, page_index) -> Page:
        """Get the page that is at the given index.

        A negative page_index, counts from the end.
        """
        if page_index < 0:
            page_index = self.page_count + page_index
        p = Page(
            page_index=page_index,
            is_current=(page_index == self.current_page_index),
        )
        p.url = self._create_url(p.page)
        return p
