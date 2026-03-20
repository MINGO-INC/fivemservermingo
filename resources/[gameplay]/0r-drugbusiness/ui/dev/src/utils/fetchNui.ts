import { isEnvBrowser } from "./misc";

export async function fetchNui<T = any>(
  eventName: string,
  data?: unknown,
  mockData?: T,
  wait?: number
): Promise<T> {
  const options = {
    method: "post",
    headers: {
      "Content-Type": "application/json; charset=UTF-8",
    },
    body: JSON.stringify(data),
  };

  if (isEnvBrowser() && mockData !== undefined) {
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve(mockData);
      }, wait || 0);
    });
  }

  const resourceName = window.GetParentResourceName
    ? window.GetParentResourceName()
    : "none";

  const resp = await fetch(`https://${resourceName}/${eventName}`, options);
  const respFormatted = await resp.json();

  return respFormatted;
}
