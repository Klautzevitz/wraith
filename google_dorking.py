import os
import time
import random
import platform
import requests
import shutil
from bs4 import BeautifulSoup
from fake_useragent import UserAgent
from googlesearch import search
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from stem import Signal
from stem.control import Controller
from requests.exceptions import RequestException
from selenium_stealth import stealth
from webdriver_manager.chrome import ChromeDriverManager

# Random user-agents for requests
ua = UserAgent()
USER_AGENTS = [ua.random for _ in range(5)]

# Tor proxy (optional)
USE_TOR = False  
TOR_PROXY = "socks5h://127.0.0.1:9050"

def start_tor():
    """Starts the Tor service based on the operating system"""
    print("[+] Checking Tor installation...")
    tor_path = None
    system = platform.system().lower()
    
    if system == "windows":
        tor_path = "C:\\Program Files\\Tor\\Tor.exe"
    elif system == "linux":
        tor_path = "/usr/bin/tor"
    elif system == "darwin":
        tor_path = "/Applications/Tor Browser.app/Contents/MacOS/tor"
    
    if tor_path and not os.path.exists(tor_path):
        print("[!] Tor is not installed or not found!")
        return False
    try:
        print("[+] Starting Tor service...")
        os.system(f"{tor_path} &")  
        time.sleep(5)  
        print("[+] Tor successfully started.")
        return True
    except Exception as e:
        print(f"[!] Error starting Tor: {e}")
        return False

def set_tor_proxy():
    """Configures the Tor proxy for requests"""
    return {"http": TOR_PROXY, "https": TOR_PROXY}

def renew_tor_ip():
    """Renews the Tor IP address"""
    with Controller.from_port(port=9051) as controller:
        controller.authenticate()
        controller.signal(Signal.NEWNYM)
        print("[+] Tor IP renewed.")

def setup_selenium():
    options = Options()
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_argument(f"user-agent={random.choice(USER_AGENTS)}")
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=options)
    
    # Apply stealth settings
    stealth(
        driver,
        languages=["en-US", "en"],
        vendor="Google Inc.",
        platform="Win32",
        webgl_vendor="Intel Inc.",
        renderer="Intel Iris OpenGL Engine",
        fix_hairline=True,
    )
    return driver

def handle_consent_popup(driver):
    """Handles the Google consent popup using JavaScript."""
    try:
        driver.execute_script("document.querySelector('.QS5gu.sy4vM').click();")
        print("[+] Consent popup handled successfully using JavaScript.")
        return True
    except Exception as e:
        print(f"[!] Could not handle the consent popup using JavaScript: {e}")

    print("[!] Could not handle the consent popup.")
    return False

def selenium_google_dork(query, max_results=10):
    """Google Dorking with Selenium"""
    print(f"[*] Starting Google search: {query}")

    driver = setup_selenium()
    try:
        driver.get("https://www.firefox.com/")
    except Exception as e:
        print(f"[!] Could not reach Google: {e}")
        driver.quit()
        return []

    # Handle the consent popup
    handle_consent_popup(driver)

    # Proceed with the search
    try:
        # Wait for the search box to be interactable
        search_box = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.NAME, "q")))
        search_box.send_keys(query)
        search_box.send_keys(Keys.RETURN)
    except Exception as e:
        print(f"[!] Error interacting with the search box: {e}")
        driver.quit()
        return []

    # Check for CAPTCHA and click the checkbox if it exists
    try:
        # Wait for the CAPTCHA iframe to appear
        WebDriverWait(driver, 5).until(
            EC.frame_to_be_available_and_switch_to_it((By.CSS_SELECTOR, "iframe[src^='https://www.google.com/recaptcha']"))
        )
        print("[+] CAPTCHA iframe found.")

        # Wait for the CAPTCHA checkbox to be clickable
        captcha_checkbox = WebDriverWait(driver, 5).until(
            EC.element_to_be_clickable((By.CLASS_NAME, "recaptcha-checkbox-checkmark"))
        )
        captcha_checkbox.click()
        print("[+] CAPTCHA checkbox clicked.")

        # Switch back to the main content
        driver.switch_to.default_content()
    except Exception as e:
        print(f"[!] No CAPTCHA checkbox found or could not click it: {e}")

    # Wait for search results to load
    try:
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//div[@class='tF2Cxc']//a")))
    except Exception as e:
        print(f"[!] Error waiting for search results: {e}")
        driver.quit()
        return []

    results = []
    links = driver.find_elements(By.XPATH, "//div[@class='tF2Cxc']//a")

    for link in links[:max_results]:
        url = link.get_attribute("href")
        if url:  # Ensure the URL is not None
            results.append(url)
            print(f"[+] Found: {url}")

    driver.quit()
    return results

def google_dork(query, max_results=10, use_proxy=False):
    """Google Dorking with googlesearch"""
    headers = {"User-Agent": random.choice(USER_AGENTS)}
    proxies = set_tor_proxy() if use_proxy else {}
    print(f"[*] Searching for: {query}")
    results = []
    
    try:
        for i, result in enumerate(search(query, num_results=max_results)):
            results.append(result)
            print(f"[+] Found: {result}")
            if use_proxy and i % 3 == 0:
                renew_tor_ip()
    except RequestException as e:
        print(f"[!] Error retrieving search results: {e}")
    
    return results
def interactive_mode():
    """Interactive menu for Google Dorking"""
    print("\n===== Google Dorking Tool =====")
    print("Choose a Dorking option:")
    print("[1] Admin login pages")
    print("[2] Sensitive files")
    print("[3] Public databases")
    print("[4] Custom query")
    print("[5] Selenium mode")

    choice = input("\nChoose an option (1-5): ").strip()

    if choice == "1":
        # Admin login pages
        admin_type = input("Enter the type of admin login page (e.g., 'WordPress', 'Joomla', 'Drupal'): ").strip()
        query = f'intitle:"{admin_type} Admin Login"'
    elif choice == "2":
        # Sensitive files
        file_type = input("Enter the file type (e.g., 'pdf', 'doc', 'xls'): ").strip()
        query = f'filetype:{file_type}'
    elif choice == "3":
        # Public databases
        data_type = input("Enter the type of data you're looking for (e.g., 'medications', 'patient records', 'financial data'): ").strip()
        query = f'intext:"{data_type}" intitle:"index of" "database" OR "sql" OR "db"'
    elif choice == "4":
        # Custom query
        query = input("Enter your custom Google Dorking query: ").strip()
    elif choice == "5":
        # Selenium mode
        query = input("Enter the query for Selenium mode: ").strip()
        max_results = int(input("Max results (default: 10): ") or 10)
        print("\n[*] Starting Selenium mode...\n")
        selenium_google_dork(query, max_results)
        return
    else:
        print("Invalid selection. Please try again.")
        return

    max_results = int(input("Number of results (default: 10): ") or 10)
    use_proxy = input("Use Tor proxy? (y/n): ").strip().lower() == "y"

    print(f"\n[*] Starting query: {query}\n")
    results = google_dork(query, max_results, use_proxy)

    if results:
        print("\n[+] Found URLs:")
        for url in results:
            print(f"- {url}")
    else:
        print("\n[!] No results found.")

if __name__ == "__main__":
    interactive_mode()