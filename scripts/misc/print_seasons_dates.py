import datetime

def find_first_wednesday(year, month):
    for day in range(1, 8):
        date = datetime.date(year, month, day)
        if date.weekday() == 2:  # 2 represents Wednesday
            return date

def print_dates(start_date, num_months):
    current_date = start_date

    for _ in range(num_months):
        first_wednesday = find_first_wednesday(current_date.year, current_date.month)
        second_date = first_wednesday + datetime.timedelta(days=25)
        third_date = first_wednesday + datetime.timedelta(days=28)

        print(f"Season: {_}")
        print(f"1) First Wednesday: {first_wednesday}")
        print(f"2) Season ends: {second_date}")
        print(f"3) Claim begins: {third_date}")
        print("---")

        # Move to the next month
        if current_date.month == 12:
            current_date = datetime.date(current_date.year + 1, 1, 1)
        else:
            current_date = datetime.date(current_date.year, current_date.month + 1, 1)

start_date = datetime.date(2023, 4, 1)
num_months = 150
print_dates(start_date, num_months)
